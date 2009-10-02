#!/usr/bin/perl
use strict;
use warnings;
use lib './lib';
use Backup::Email::GUI;

my $gui = Backup::Email::GUI->new();
$gui->MainLoop;

exit 0;
