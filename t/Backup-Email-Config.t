package OTest;
use Moose;
use Data::Dumper;

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

my @list = $config->file_list; # list context (lvalue is list)
is( @list, 20,'checked arraify working correctly'); # this is how array refs should be used from the YAML
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


my %hash = $config->just_a_hash; # still list context..actually hash context..
is( keys %hash , 2 , 'testing a hash as value');

#the following test should pass if Want.pm can find out if an object or scalar is required as return value from AUTOLOAD
#most cases we'll use in the code will be with the output a scalar
#ok($config->just_a_hash->first_key eq 'stuff','test scalar');

# tests for g

ok($config->g qw/just_a_hash first_key/ eq 'stuff','test g()');
ok($config->g qw/hash_with_arrays 1/ eq 'item2', 'test g() 2');

eval { $config->g qw/hash_with_arrays wrong/; };
ok($@ =~ /expected/, 'error from g() ');

