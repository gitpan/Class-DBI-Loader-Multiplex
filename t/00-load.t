#!perl -T

use Test::More tests => 5;

BEGIN {
	use_ok( 'Exporter' );
	use_ok( 'UNIVERSAL::exports' );
	use_ok( 'Class::DBI::Loader' );
	use_ok( 'DBD::Multiplex' );
	use_ok( 'Class::DBI::Loader::Multiplex' );
}

diag( "Testing Class::DBI::Loader::Multiplex $Class::DBI::Loader::Multiplex::VERSION, Perl $], $^X" );
