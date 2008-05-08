use strict;
use warnings;
#use ExtUtils::MakeMaker;

use inc::Module::Install;
name 'Class-DBI-Loader-Multiplex';
all_from 'lib/Class/DBI/Loader/Multiplex.pm';

requires 'Class::DBI::Loader' => 0.34;

build_requires 'Test::More' => 0.32;

use_test_base;
auto_include;
WriteAll;

#WriteMakefile(
#    NAME                => 'Class::DBI::Loader::Multiplex',
#    AUTHOR              => 'NaokiURAI <naokiurai@cpan.org>',
#    VERSION_FROM        => 'lib/Class/DBI/Loader/Multiplex.pm',
#    ABSTRACT_FROM       => 'lib/Class/DBI/Loader/Multiplex.pm',
#    PL_FILES            => {},
#    PREREQ_PM => {
#        'Test::More' => 0,
#    },
#    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
#    clean               => { FILES => 'Class-DBI-Loader-Multiplex-*' },
#);
