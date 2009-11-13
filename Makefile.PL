
use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  DISTNAME  => 'Backup-Email',
  NAME      => 'Backup::Email',
  AUTHOR    => "Stefan\ Petrea\ \<stefan\.petrea\@gmail\.com\>",
  ABSTRACT  => "A\ backup\ application\ specifically\ built\ for\ backing\ up\ files\ to\ an\ IMAP\ server\.",
  VERSION   => '0.02',
  EXE_FILES => [ qw() ],
  (eval { ExtUtils::MakeMaker->VERSION(6.31) } ? (LICENSE => 'perl') : ()),
  PREREQ_PM    => {
    "Alien::wxWidgets" => '0',
    "Wx" => '0',
    "DateTime" => '0',
    "Mail::IMAPClient" => '0',
    "Net::SSLeay" => '0',
    "IO::Socket::SSL" => '0',
    "DBM::Deep" => '0',
    "YAML" => '0',
    "Archive::Zip" => '0',
    "Net::SMTP::TLS" => '0',
    "List::AllUtils" => '0',
    "MooseX::NonMoose" => '0',
    "List::Util" => '0',
    "MIME::Base64" => '0',
    "MIME::Lite" => '0',
    "List::MoreUtils" => '0',
    "Moose" => '0',
  },
  test => {TESTS => 't/*.t'}
);

