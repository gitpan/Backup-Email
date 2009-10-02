package Backup::Email::Config;
#this package will be used to refactor the use of the configuration file
use Moose;
use strict;
use warnings;
use YAML qw/LoadFile DumpFile/;
use Data::Dumper;
use Carp qw/confess/;
#use MooseX::Types::Moose qw/HashRef Str/;
use feature 'say';
use overload 
	'@{}'	=> \&arrayify,
	'""'	=> \&stringify;
our $AUTOLOAD;

=pod

=head1 NAME

Backup::Email::Config - A module that maps naturally keys a YAML file over method names

=head1 DESCRIPTION

This module was written to map every item from an YAML to a chain of calls of methods
of an object.
It's intended to ease the use of a YAML.


I<quote>:
C<< <@nothingmuch> it's kinda like making an omlette with a remote control >>


=head1 CONFIGURATION FILE

	ID: <id_of_machine>
	from: <some_address>
	imap: <imap_server>
	password: <yourpassword>
	smtp: <your_smtp_server>
	to: <address_you_want_to_send_to>
	username: <username>
	file_list:
		- c:\Perl\stuff
		- c:\Program Files\Vim\vim72\_vimrc


The configuration file -> config.yml should be located in the same directory with app.pl.

The desired behaviour is the following:

=head1 SYNOPSIS

Having an object $c of type Backup::Email::Config ( the naming should probably change to something more general )
and an YAML file for example:

        ---
        ID: man
        animal: pig
        object:
              - pq
              - qp
              - test
        one:
              two:
                      three: thrice

We list the following calls:

=begin html

<table border=1>
<tr>
<th> CALL				</th><th> RETURN VALUE 		</th>
</tr>

<tr>
</td><td>$c->ID 				</td><td> 'man'			</td>
</tr>

<tr>
</td><td>$c->animal				</td><td> 'pig'		 	</td>
</tr>

<tr>
</td><td>$c->object				</td><td> ('pq','qp','test')	</td>
</tr>

<tr>
</td><td>$c->object(0)			</td><td> 'pq'			</td>
</tr>

<tr>
</td><td>$c->object(1)			</td><td> 'qp'			</td>
</tr>

<tr>
</td><td>$c->one				</td><td> {two=>{three=>thrice}}</td>
</tr>

<tr>
</td><td>$c->one->two			</td><td> {three=>thrice}	</td>
</tr>
</table>

=end html

=head1 HOW IT WORKS

We're using AUTOLOAD to catch undefined method calls , and we strip them off of their namespace, and we push them in an array(chain).

AUTOLOAD always returns $self so this allows for chaining of the undefined methods.

We overload the arrayify and stringify subs. (arrayify is just a proxy to stringify)

In stringify we need to get our array(chain) and step-by-step get to the data we need.

So if in the chain we have ('one','two','three') our expression will look actually access $self->_config->{one}->{two}->{three},

but we just called $c->one->two->three which is pretty natural.

=head1 TODO

We need to have in AUTOLOAD wantarray to check out if on the other side we want an array in order to return one.

=cut

has _config => (
	isa	=> 'HashRef',
	is	=> 'rw',
);

has _config_path => (
	isa	=> 'Str',
	is	=> 'rw',
);


has chain	=> (
	isa	=> 'ArrayRef',
	is	=> 'rw',
	default	=> sub{[]},
);

has last_config_item => (
	isa	=> 'Str',
	is	=> 'rw',
	default	=> '',
); # last config item resulted from a chain


has temp_change => ( # if change is part of the chain last_config_item needs to be passed to him also
	isa	=> 'Str',
	is	=> 'rw',
	default	=> '',
); # last config item resulted from a chain



sub BUILDARGS {
	my ($self,$file) = @_;
	confess
	'config parameter invalid and default config.yml path invalid' if !defined($file) && !(-e '../config.yml');
	{
		_config_path	=> $file// '../config.yml' 
	};
};

#after 'new' => {
sub BUILD {
	my ($self) = @_;
	$self->_config( LoadFile($self->_config_path) );
}

sub reload {
	my ($self) = @_;
	$self->_config( LoadFile($self->_config_path) );
}


#
# Here we just take any method applied to this class and associate it to some
# value in the YAML ( accessors on the fly )
#



sub AUTOLOAD {
	# this is a link in the chain
	
	# will also be called if you misspell an existing method ... no cure for that , unless it's not in the YAML either and then
	# some kind of warning/exception should pop up , will have to implement this
	my ($self,$index) = @_;
	#say "AUTOLOAD: $AUTOLOAD";
	# should verify that AUTOLOAD starts with Backup::Email::Config , otherwise return to 'normal' flow
	$AUTOLOAD =~ s/^.*::(\w*)$/$1/; # actually , we don't need the rest
	push @{$self->chain()} , [ $1 , $index ];
	return $self;
};

sub arrayify {
	my ($self) = @_;
	#say "DEBUG: ARRAYIFY is CALLED!";
	# actually dereferencing an array ref but WTH
	
	# this is for this particular case   my @stuff = <Backup::Email::Config>->m1->m2->m3;
	# it will call arraify because Backup::Email::Config is a blessed hash that needs to be
	# dereferenced in order to be converted to an array , however we overload this
	 # let stringify take care of cleaning stuff up also
	return $self->stringify();
}


sub stringify {
	my ($self) = @_;
	#need to update this logic to the context of stringify
	#say "DEBUG: STRINGIFY is CALLED!";
	confess "chain empty inside stringify()" unless @{ $self->chain };
	my $return = $self->_config; # $return will be a HASH throughout the following loop and at the end a SCALAR or ARRAYREF
	for my $call ( @{$self->chain} ) {
		my ($name,$index) = @$call;
		if	( defined $index ) {
			$return = $return->{$name}->[$index];
			$self->last_config_item( $self->last_config_item . "->{$name}->[$index]" );
		} elsif	( defined $name ) {
			$return = $return->{$name} if ref($return) eq 'HASH';
			$self->last_config_item( $self->last_config_item . "->{$name}" );
		}
	};
	$self->temp_change($self->last_config_item);
	$self->last_config_item('');
	$self->chain([]); # clean the chain
	return $return;
}


sub debug {
	my ($self) = @_;
	say "last_config_item	: ".$self->last_config_item;
	say "temp_change	: ".$self->temp_change;
}

sub change { # append this to the end of the chain to modify and save the conf file
	my ($self,$what) = @_;

	"$self"; #force stringify to be called to get temp_change right because if we append change to the chain stringify won't be called any more	 
	# will cause a warning
	my $expr = '$self->_config'.$self->temp_change.'=$what;';


	eval $expr; # we modify our $self->_config
	DumpFile($self->_config_path,$self->_config); # save the changes on disk
	$self->last_config_item(''); # clear the last_config_item
	$self->temp_change('');
}



=head1 SEE ALSO

If you're interested in similar modules, take a look at 

L<Data::AsObject> , L<Data::Hive> , L<MooseX::YAML>

=head1 BUGS

If this module has any bugs please report them to rt.cpan.org or my email.

Also if you have any suggestions on the code you are welcome to drop me an e-mail.

=head1 AUTHOR

Stefan Petrea, C<< <stefan.petrea at gmail.com> >>


=cut

1;

