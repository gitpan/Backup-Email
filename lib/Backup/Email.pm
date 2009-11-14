# 
# This file is part of Backup-Email
# 
# This software is copyright (c) 2009 by Stefan Petrea.
# 
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# 
use strict;
use warnings;
# Every program attempts to expand until it can read mail. Those programs which cannot so expand are replaced by ones which can. -> jwz
package Backup::Email;
use strict;
use warnings;
use Moose;
use feature 'say';
use Mail::IMAPClient;
use Mail::IMAPClient::BodyStructure;
use IO::Socket::SSL;
use Data::Dumper;
use MIME::Base64 qw/decode_base64/; #doesn't work properly on Windows , produces invalid 7z and characters outside base64 set
use List::Util;
use List::MoreUtils;
use DBM::Deep;
use 5.010000;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Backup::Email ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.015';




=pod

=head1 NAME

Backup::Email - A backup application specifically built for backing up files to an IMAP server.

=head1 VERSION

version 0.021

=head1 DESCRIPTION


This module coupled with Backup::Email::GUI is intended to help you backup configuration
files on your system( as well as other files that you want to specify in the configuration YAML file ).

It receives functionality for sending e-mails from the Backup::Email::Send role.

It inherits Backup::Email::Config so it can access easily the config.yml that you need to provide.

It caches some e-mail headers in messages.db using DBM::Deep so it will run faster on sub-sequent runs.

(Normally you should use something like revision control or just ftp but this is probably )

=head1 SYNOPSIS

=over 

=item config.yml file 

    The configuration file needs to specify the credentials of the e-mail and a list of files to back up.
    Your config file should be named 'config.yml' and placed in your appdir directory.

        ---
        ID: toshiba
        file_list:
          - /home/user/.muttrc
          - /etc/passwd
          - /home/user/.opera/
        imap: imap.gmail.com
        smtp: smtp.gmail.com
        appdir: /path/to/where/config.yml/is
        from: <from-email>
        to: <to-email>
        password: <your_password>
        username: <your_username>

=back



=head1 client

Mail::IMAPClient object used to log-in

=head1 getMessageFile($uid)

This method will get the attached zip file for the message with uid = $uid , decode it base64( because it's supposedly coded base64 if it's been sent by Backup::Email ) and store it on disk.

=head1 check_if_connected()

Checks if we are connected, otherwise exits immediately.

=head1 check_folder($folder,$code)

Gets all messages sent by Backup::Email to the e-mail address and runs the the subref $code on each of them.
The $code sub receives the following parameters:

=begin html

<ul>
<li>$self of Backup::Email object
<li>hashref with keys 'Date' , 'Subject' , 'From'
<li>uid
</ul>

=end html 

It also uses DBM::Deep to store already fetched message headers(in messages.db) from your e-mail so it will load up faster on sub-sequent runs.

=head1 files_to_zip()

This method provides the list of files that need be zipped. This method is used by the make_to_zip() provided by the role Backup::Zip.

=cut


with 'Backup::Zip'; # this role makes the assumption that the Class consuming it has a ->files_to_zip method available
with 'Backup::Email::Send';
extends 'Backup::Email::Config'; # that way we'll get configuration stuff 'for free'

has socket => (
	isa	=> 'Any',
	is	=> 'rw',
	lazy	=> 1,
	default	=> sub {
		my ($self) = @_;
		IO::Socket::SSL->new(
			PeerAddr => "".$self->imap,
			PeerPort => 993,
		)
			or die "socket(): $@"
	},
);



has client => (
	isa	=> 'Any',
	is	=> 'rw',
	lazy	=> 1,
	default	=> sub {
		my ($self) = @_;
		Mail::IMAPClient->new(
			Socket	=> $self->socket,
			User	=> "".$self->username, # we need stringification
			Password=> "".$self->password,
			Uid	=> 1,
		)
			or die "new(): $@"
	},
);

sub check_if_connected {
	my ($self) = @_;

	if($self->client->IsAuthenticated() ){
		say "Authenticated \n";
	} else {
		say "Authentication failed \n";
		exit(-1);
	};
        #my @folders = $self->client->folders();
	#print join("\n* ", 'Folders:', @folders), "\n";
}


sub check_folder {
	my ($self,$folder,$code) = @_;
        my $dbm_file = 'messages.db';

        my $not_first_time =-f $dbm_file;
        my $db = DBM::Deep->new(
            file=>  $dbm_file,
            type => DBM::Deep->TYPE_ARRAY
        );

        # TODO -> $self->last_message_read will be replaced by just getting the first(if there is one) uid from message.db ($db)

	$self->client->select($folder);
	# pt parse_headers e by default peek pe 1 dar pt restul e pe 0
	my @uids = $self->client->search('SUBJECT "[configuration]"'); #->recent

        my $last_uid = 0;#biggest uid in the first loop
        # processing fresh uids


        say "FIRST:".$uids[0];
        if( !defined($self->last_message_read) || $uids[-1] > int($self->last_message_read) ) {
            for my $uid ( @uids ) {
                my $hashref = $self->client->parse_headers($uid,"Date","Subject","From");

                next if (
                    index( $hashref->{"Subject"}->[0] , $self->ID )<0
                    || !$uid
                    || ( defined($self->last_message_read) && $uid <= int($self->last_message_read) )
                );
                #say "UID=$uid"." ".int($self->last_message_read);
                $db->unshift({
                        uid => $uid,
                        %$hashref
                });
                $code->($self,\$hashref,$uid);
                $last_uid = 
                    $last_uid < $uid 
                    ? $uid 
                    : $last_uid;
            };
        };
        $self->last_message_read->change($last_uid) if $last_uid;

        say "!!!starting to use cache";
        # processing the cache
        if( $not_first_time ) {
            for my $i ( 0..$db->length() ) {
                my $hashref = $db->get($i);
                next if ($last_uid && $hashref->{uid}+1 > $last_uid );
                say "UID=".$hashref->{uid};
                $code->( $self, \$hashref, $hashref->{uid} );
            }
        }
}


sub getMessageFile {
	my ($self,$uid) = @_;
	say "in getMessage";

	my $struct = Mail::IMAPClient::BodyStructure->new( 
		$self->client->fetch($uid, "bodystructure")
	);

	# say Dumper $struct; 
	unlink "config.base64";
	unlink "config.zip";
	#have to remove these two on SIGQUIT or Wx close event

	
        if( $^O =~ /MSWin32/ ) {
	    open my $config_archive , ">config.base64";
            # here we get the second attachment , normally we should enumerate
            # the parts and select the one who has the content type of an archive
            # and after that docode and store on disk
            # probably will need unlink, rename, File::Copy for various operations with the files
            print $config_archive $self->client->bodypart_string($uid,2);
            #TODO -> try on windows to use  binmode FILEHANDLE nad this should fix it and eliminate the need for base64.exe
            system "base64 -d -n config.base64 > config.zip"; # this is not needed on Linux , where base64 from MIME::Base64 works properly
        } elsif ( $^O =~ /linux/ ) {
            say "I'm on linux";
	    open my $config_archive , ">config.zip";
            print $config_archive decode_base64( $self->client->bodypart_string($uid,2) );
        };
}



# needed for Zip Role composition
sub files_to_zip {
	my $self = shift;
        confess "[ERROR] no files to zip in configuration file" unless $self->file_list;
	my @return = @{$self->file_list};
	push @return,$self->appdir.'/config.yml';
	return @return;
}


=head1 GUI

The Backip::Email comes with a GUI which you can use by running using app.pl

=begin html

<img src="http://perlhobby.googlecode.com/svn/trunk/scripturi_perl_teste/backup_pl/GUI.png" />

=end html

=head1 NOTES

Normally you would use some version control for backing things up like this but I decided to write the module anyway.

=head1 BUGS

You can use the CPAN Request Tracker http://rt.cpan.org/ and submit
new bugs under

  http://rt.cpan.org/Ticket/Create.html?Queue=Backup::Email


=head1 SEE ALSO

L<Backup::Email::GUI> , L<Backup::Email::Config> , L<Backup::Zip> , L<Backup::Email::Send>

=cut

1;