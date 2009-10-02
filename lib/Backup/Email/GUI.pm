package Backup::Email::GUI;
use strict;
use warnings;
use Moose;
use MooseX::NonMoose; # for inheriting from Non-Moose classes
use Backup::Email;
use feature 'say';
use Data::Dumper;
use DateTime;
use Archive::Zip;
use List::MoreUtils qw(each_arrayref);
# Wx::Perl::* is the namespace for a lot of Wx controls

use Wx qw(:listctrl wxRED wxBLUE wxITALIC_FONT wxDefaultPosition wxDefaultSize);
use Wx::Event qw( EVT_BUTTON);
eval { require 'Wx::ListCtrl' };

extends 'Wx::App';

=pod


=head1 NAME

Backup::Email::GUI - This is a GUI written using the Wx bindings for Backup::Email.

=head1 SCREENSHOT

=begin html

<img src="http://perlhobby.googlecode.com/svn/trunk/scripturi_perl_teste/backup_pl/GUI.png" />

=end html

=head1 map_multiple($code,@cols)

Extends the Perl 'map' operator to iterating over multiple lists at the same time.

Parameters

=over

=item * $code

This is the code that is going to be run, $code is a subref. $code will receive a list of arguments formed by getting one argument
from each of the arrayrefs in @cols.

=item * @cols

@cols is an list of arrayrefs.

=back


=head1 BUGS

If this module has any bugs please report them to rt.cpan.org or my email.

Also if you have any suggestions on the code you are welcome to drop me an e-mail.

=head1 AUTHOR

Stefan Petrea, C<< <stefan.petrea at gmail.com> >>

=cut




# TODO -> make these constants
# a couple of constant IDs needed for Wx widgets
my $RESTORE_ID = 3;
my $BACKUP_ID    = 4;
my $LISTCTRL_ID = 8;

has backup => (
	isa	=> 'Any',
	is	=> 'rw',
	lazy	=> 1,
	default	=> sub {
		my $b = Backup::Email->new('/home/spx2/config.yml');
		$b->check_if_connected;
		$b;
	},
);

has frame => (
	isa	=> 'Any',
	is	=> 'rw',
	lazy	=> 1,
	default	=> sub {
		say "frame created";
		return Wx::Frame->new( undef,         # Parent window
			-1,            # Window id
			'Email Backup', # Title
			[400,100],         # position X, Y
			[850,400]     # size X, Y
		);
	}
);

has list => (
	isa	=> 'Any',
	is	=> 'rw',
	lazy	=> 1,
	default	=> sub {
		my $self = shift;
		return Wx::ListCtrl->new( 
			$self->frame, 
			$LISTCTRL_ID, 
			wxDefaultPosition, 
			[800,300] , 
			wxLC_REPORT 
		);
	}
);


sub RESTORE {
	my $self = shift;
	say "RESTORE pressed";
	#say Dumper $self->GetSelectedItem;
	my $selected = $self->GetSelectedItem;
	if( defined $selected ) {
            # Cwd::abs_path, File::Spec->rel2abs , portable way  to turn relative -> absolute path 
            my $where_to_extract = '/home/spx2/backup_pl/unpacked/';
            `mkdir $where_to_extract`;
            `rm $where_to_extract/*`;
            my $uid = $self->list->GetItem($selected,0)->GetText;
            my $raw_data = $self->backup->getMessageFile($uid);
            my $archive = Archive::Zip->new('config.zip');
            $archive->extractTree('',$where_to_extract);
	} else {
            warn "[WARNING] No message was selected to restore from"; #
        };
}

sub BACKUP {
	my $self = shift;
        confess "[ERROR] You need a ID in your configuration YAML file" unless $self->backup->ID;
        my $zipfile = 'configs.zip';
        `rm $zipfile`;
        say Dumper $self->backup->files_to_zip();
        $self->backup->make_zip($zipfile);
        $self->backup->sendEmail({
                subject => 
                    'backup '.$self->backup->ID.' '.DateTime->now.' OS='.$^O.' [configuration]' ,
                file    => $zipfile,
                body    => join("\n",$self->backup->files_to_zip()),
        });
	say "BACKUP pressed";
}


sub GetSelectedItem {
	my ( $self ) = @_;  
	# find selected items
	my $item = -1;
	while(1) {
		$item = $self->list->GetNextItem(
			$item,      
			wxLIST_NEXT_ALL,
			wxLIST_STATE_SELECTED
		);
		last if(-1 == $item);
		return $item;
	};
	return undef;
}


sub map_multiple {
	my ($self,$code,@cols) = @_;
	my $columns = each_arrayref(@cols);
	while( my @pair = $columns->() ) {
		$code->(@pair);
	}
}


sub OnInit {
	my $self = shift;

	my $row_id = 1;
	#my $wlc = $self->frame->{LISTCTRL}; = ;



	$self->frame->{ RESTORE } = Wx::Button->new($self->frame, $RESTORE_ID, 'RESTORE' , [40,300] );
	EVT_BUTTON( $self->frame , $RESTORE_ID , sub { $self->RESTORE } );


	$self->frame->{ BACKUP } = Wx::Button->new($self->frame, $BACKUP_ID, 'BACKUP' , [130,300] );
	EVT_BUTTON( $self->frame , $BACKUP_ID , sub { $self->BACKUP } );



	#my $columns = each_arrayref(
		#[0..3],
		#[qw/uid	From	Subject	Date/],
		#[qw/80	110	400	180/],
	#);
	#while( my ($idx,$name,$width) = $columns->() ) {
		#$self->list->InsertColumn($idx, $name );
		#$self->list->SetColumnWidth($idx,$width);
	#}

	$self->map_multiple( 
		sub {
			$self->list->InsertColumn($_[0], $_[1] );
			$self->list->SetColumnWidth($_[0],$_[2]);
		},
		[0..3], # $_[0]
		[qw/uid	From	Subject	Date/], # $_[1]
		[qw/80	110	400	180/], # $_[2]
	);



	say "here";

	$self->backup->check_folder('INBOX',
		sub {
			my ($s,$hashref,$uid) = @_; # From Subject Date


                        $hashref = ${ $hashref };
                        #say Dumper $hashref;
                        # took out the shift because it would modify the DBM::Deep on disk as well
			my $from	= @{$hashref->{'From'}}[0];
                        my $subject	= @{$hashref->{'Subject'}}[0];
                        my $date	= @{$hashref->{'Date'}}[0];

			my $entry_id = $self->list->InsertStringItem( $row_id , 2 );
			$self->list->SetItemData( $entry_id, int rand 100 );

			#$self->list->SetItem($entry_id,0,"$uid");
			#$self->list->SetItem($entry_id,1,$from);
			#$self->list->SetItem($entry_id,2,$subject);
			#$self->list->SetItem($entry_id,3,$date);

			$self->map_multiple(
				sub {
					$self->list->SetItem($entry_id,$_[0],$_[1]);
				},
				[0..3],
				["$uid",$from,$subject,$date]
			);


			#print "\n$uid\n";
			$row_id++;
		}
	);

	$self->SetTopWindow($self->frame);    # Define the toplevel window
	$self->frame->Show(1);                # Show the frame
	1;
}




1;
