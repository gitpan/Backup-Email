package Backup::Zip;
use Moose::Role;
use Archive::Zip qw/:ERROR_CODES :CONSTANTS/;
use Carp qw/confess/;
use 5.008;
use strict;
use warnings;


requires 'files_to_zip';


=pod


=head1 NAME

Backup::Zip - A Zip Role for classes using Moose


=head1 VERSION

version 0.02

=head1 SYNOPSIS

        package CanZipThings;
        use Moose;
        with 'Backup::Zip';

        sub files_to_zip() {
            return (
                '/etc/passwd',
                '/etc/bashrc',
            );
        }

        package main;
        use CanZipThings;

        my $canzip = CanZipThings->new;
        $canzip->make_zip("/tmp/somezip.zip");

=head1 DESCRIPTION

This is a Role and it provides a zip function to the consumer class.

=head1 files_to_zip()

Backup::Zip is a Role and it depends on the files_to_zip() method which it expects the
consumer class to provide.
This method will be used by make_zip() in order to get an array of the files it will zip
so the return value should be a list with filepaths.

=head1 make_zip($zip)

This method uses Archive::Zip to zip your files and stores them in the path indicated by $zip.
If you provide no arguments , it will 'confess' with an error message.
You will also receive warnings for all the files that don't exist.

=head1 unzip($what,$where)  - unimplemented!

This method will unzip the files found at the path $what to the path $where.

=head1 BUGS

If this module has any bugs please report them to rt.cpan.org or my email.

Also if you have any suggestions on the code you are welcome to drop me an e-mail.

=head1 AUTHOR

Stefan Petrea, C<< <stefan.petrea at gmail.com> >>

=cut





sub make_zip {
	my ($self,$zip) = @_;
	confess 'missing zip filename as argument' unless $zip;
	my $zip_obj = Archive::Zip->new();
	for my $file ( $self->files_to_zip ) { # $file can be a directory also
		if	( -e $file ) {
			$zip_obj->addTree($file,'');
		} else {
			warn "File not found -> ".$file; 
		};
	};
	if ( $zip_obj->writeToFileNamed($zip) != AZ_OK ) {
		confess 'cannot write zip file';
	}
}

1;