package TestSend;
use lib './lib';
use Moose;
with 'Backup::Email::Send';

package TestSend2;
use Moose;
extends 'Backup::Email::Config';
with 'Backup::Email::Send';

package TestSend3;
use Moose;

sub BUILD {
    my $self = shift;
    $self->meta->add_method( $_ => sub {} )
        for qw/to from username password smtp/
}

with 'Backup::Email::Send';


package main;
use Test::More qw/no_plan/;


# tests for the Backup::Email::Send role

eval { TestSend->new(); };
ok($@,"role Backup::Email::Send wasn't composed because the inherited class didn't provided the needed methods");
eval { TestSend2->new('t/config.yml') };
ok(!$@,"role Backup::Email::Send was composed because the mehtods it needs are provided from an inherited class");
eval { TestSend3->new };
ok(!$@,"role Backup::Email::Send was composed because the mehtods it needs are provided from the class that is consuming the role");


exit 0;
