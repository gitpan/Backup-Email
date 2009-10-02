package OTest;
use Moose;
extends 'Backup::Email::Config';


sub test_method {
    my $self = shift;
    $self->last_message_read->change(2600);
}




package main;
use feature 'say';
use Test::More qw/no_plan/;
use Data::Dumper;
use lib './lib';
use Backup::Email::Config;
#print Dumper \%INC;
#print Dumper \@INC;




my $config = Backup::Email::Config->new('t/config.yml');
#say Dumper \$config;


is($config->ID,'toshiba','one-key mapping to method check');
is($config->just_a_hash->first_key,'stuff','chained access to value');
is($config->just_a_hash->second_key,'other_stuff','yet another chained access to value');
is($config->hash_with_arrays(1),'item2','accessing array of YAML with index');


$config->just_a_hash->first_key->change("new_stuff");
$config->reload();
is($config->just_a_hash->first_key,'new_stuff','check that method change() works properly');
$config->just_a_hash->first_key->change("stuff");
is($config->just_a_hash->first_key,'stuff','check change() again');
is(eval{ scalar @{$config->file_list} },20,'checked arraify working correctly'); # this is how array refs should be used from the YAML
# my @return = @{$self->file_list}; <-- this works fine also



my $obj = OTest->new('t/config.yml');
eval {
    $obj->test_method();
};

is( $@ , '','no errors for Object inheriting Backup::Email::Config and using some AUTOLOAD method');

# TODO -> add tests for arraify()

#$config->just_a_hash->first_key->change("new_stuff"); # old value was "stuff"


#is($config->hash_with_arrays->(1),'item2','one-key mapping to method check');
#isnt($config->something_that_doesnt_belong,'500','one key that does not exist');



