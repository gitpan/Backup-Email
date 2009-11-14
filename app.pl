#!/usr/bin/perl
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
use strict;
use warnings;
use lib './lib';
use Backup::Email::GUI;

my $gui = Backup::Email::GUI->new();
$gui->MainLoop;

exit 0;