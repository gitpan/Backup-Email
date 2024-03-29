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
package Backup::Email::Send;
use Moose::Role;
use Carp qw/confess/;
use MIME::Lite;
use List::AllUtils qw/all/;
use Net::SMTP::TLS;
use Data::Dumper;
=pod

=head1 NAME

Backup::Email::Send - A role for sending e-mails.

=head1 VERSION

version 0.022

=head1 DESCRIPTION

This role will provide sending e-mails capabilities to the class that consumes it.
It's requirements are either the class that consumes the role is Backup::Email::Config or it provides methods:

=over

=item * to()

=item * from()

=item * smtp()

=item * username()

=item * password()

=back

=head1 attachFile($path)

Adds a given existing file to the list of files which will be attached to the e-mail

=head1 sendEmail($href)

$href is HashRef which contains 2 keys: subject,body.
It must be filled if you want to have those two attributes for the e-mail you are sending.
Also , here , the list of files are checked and attached to the e-mail message.

=head1 TODO

It should also allow for attributes instead of the methods.

=head1 BUGS

If this module has any bugs please report them to rt.cpan.org or my email.

Also if you have any suggestions on the code you are welcome to drop me an e-mail.

=head1 AUTHOR

Stefan Petrea, C<< <stefan.petrea at gmail.com> >>

=cut

#
# we are using functions generated by AUTOLOAD, it would be nice
# if we could do a require on ->to,->from,->smtp,->username,->password it would be
# very good , so that we can make at least a check for being able to compose this
# role with a particular class
#


has attachments => (
    isa => 'ArrayRef[Str]',
    is  => 'rw',
    default => sub {[]},
);


sub BUILD {
    my $self = shift;
    confess qq/
    [ERROR]
    The class that consumes Backup::Email::Send needs to inherit
    from Backup::Email::Config as well or at least provide all of the following methods
    ->to , ->from , ->username , ->password , ->smtp
    / unless (
        $self->isa('Backup::Email::Config')
        ||
        all { $self->does($_) }
            qw/to from username password smtp/
    );
};




sub attachFile {
	my ($self,$path) = @_;
        confess "file $path to be attached does not exist" unless -f $path;
        push @{$self->attachments},$path;
}

sub sendEmail {
	my ($self,$href) = @_;

	my $msg = MIME::Lite->new(
		From	=> "".$self->to,
		To	=> "".$self->from,
		Subject	=> $href->{subject},
                Type    => 'TEXT',
                Data    => $href->{body},
	);


        warn "no file attachments" unless @{$self->attachments};

        -f $_
        ?   $msg->attach(
		Type	=> 'application/octet-stream',
		Path	=> $_,
            )
        : warn "file $_ does not exist"
            for @{$self->attachments};

	my $smtp_tls =  MIME::Lite::SMTP::TLS->new(
		"".$self->smtp,
		User		=> "".$self->username,
		Password	=> "".$self->password,
		Port		=> 587,
	);

	$smtp_tls->mail("".$self->from);
	$smtp_tls->to("".$self->to);

        print Dumper $msg;
	$smtp_tls->data();
	$msg->print_for_smtp($smtp_tls);
	$smtp_tls->dataend();
        # here need to check if e-mail has been sent, otherwise throw exception

        $self->attachments([]);#erase all attachments if email has been sent succesfuly
}


# monkeypatching a.k.a make new 'fake' package to inject a new method in it ( ::print is needed by $msg->print_for_smtp )
@MIME::Lite::SMTP::TLS::ISA = qw( Net::SMTP::TLS );
sub MIME::Lite::SMTP::TLS::print { shift->datasend(@_) }

1;