use 5.010000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Backup::Email',
    VERSION_FROM      => 'lib/Backup/Email.pm', # finds $VERSION
    PREREQ_PM         => {
        'Archive::Zip'      => 0,
        'Alien::wxWidgets'  => 0,
        'Wx'                => 0,
        'DateTime'          => 0,
        'Moose'             => 0,
        'MooseX::NonMoose'  => 0,
        'List::AllUtils'    => 0,
        'List::Util'        => 0,
        'List::MoreUtils'   => 0,
        'DBM::Deep'         => 0,
        'YAML'              => 0,
        'Mail::IMAPClient'  => 0,
        'Net::SMTP::TLS'    => 0,
        'IO::Socket::SSL'   => 0,
        'Net::SSLeay'       => 0,
        'MIME::Lite'        => 0,
        'MIME::Base64'      => 0,
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Backup/Email.pm', # retrieve abstract from module
       AUTHOR         => 'Stefan Petrea <stefan.petrea@gmail.com>') : ()),
);
