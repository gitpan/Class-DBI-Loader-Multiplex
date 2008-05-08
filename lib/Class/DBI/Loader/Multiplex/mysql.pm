package Class::DBI::Loader::Multiplex::mysql;

use strict;
use warnings;
no warnings qw/ redefine /;

use Exporter;
use UNIVERSAL::exports;

use vars qw/ $VERSION @ISA @EXPORT /;
@ISA     = qw/ Exporter /;
@EXPORT  = qw/
    _relationships _tables
/;

$VERSION = 0.01;

sub _relationships {
    my $self   = shift;
    my @tables     = $self->tables;
    my @dsn_master = $self->{'_get_master_datasource'}();
    my $dbh        = DBI->connect(@dsn_master) or Carp::croak($DBI::errstr);
    my $dsn        = $dsn_master[0];
    my %conn       =
        $dsn =~ m/^dbi:\w+:([\w=]+)/i
        && index( $1, '=' ) >= 0
        ?  split( /[=;]/, $1 )
        :  ( database => $1 );
    my $dbname    = $conn{database} || $conn{dbname} || $conn{db};
    die Carp::croak("Can't figure out the table name automatically.") if !$dbname;
    my $quoter    = $dbh->get_info(29);
    my $is_mysql5 = $dbh->get_info(18) =~ /^5./;
    foreach my $table (@tables) {
        if ( $is_mysql5 ) {
            my $query = qq(
                SELECT column_name,
                       referenced_table_name
                  FROM information_schema.key_column_usage
                 WHERE referenced_table_name IS NOT NULL
                   AND table_schema = ?
                   AND table_name = ?
            );
            my $sth = $dbh->prepare($query)
                or die Carp::croak("Cannot get table information: $table");
            $sth->execute($dbname, $table);
            while ( my $data = $sth->fetchrow_hashref ) {
                eval { $self->_has_a_many( $table, $data->{column_name}, $data->{referenced_table_name} ) };
                warn qq/\# has_a_many failed "$@"\n\n/ if $@ && $self->debug;
            }
            $sth->finish;
        } else {
            my $query = "SHOW TABLE STATUS FROM $dbname LIKE '$table'";
            my $sth   = $dbh->prepare($query)
              or die Carp::croak("Cannot get table status: $table");
            $sth->execute;
            my $comment = $sth->fetchrow_hashref->{comment};
            $comment =~ s/$quoter//g if ($quoter);
            while( $comment =~ m!\(`?(\w+)`?\)\sREFER\s`?\w+/(\w+)`?\(`?\w+`?\)!g ){
                eval { $self->_has_a_many( $table, $1, $2 ) };
                warn qq/\# has_a_many failed "$@"\n\n/ if $@ && $self->debug;
            }
            $sth->finish;
        }
    }
    return;
}

sub _tables {
    my $self = shift;
    my $dbh = DBI->connect($self->{'_get_master_datasource'}()) or Carp::croak($DBI::errstr);
    my @tables;
    foreach my $table ( $dbh->tables ) {
        if(my $catalog_sep = quotemeta($dbh->get_info(41))) {
          $table = (split($catalog_sep, $table))[-1]
            if $table =~ m/$catalog_sep/;
        }
        my $quoter = $dbh->get_info(29);
        $table =~ s/$quoter//g if ($quoter);
        push @tables, $1
          if $table =~ /\A(\w+)\z/;
    }
    $dbh->disconnect;
    return @tables;
}

=head1 NAME

Class::DBI::Loader::Multiplex::mysql -  Class::DBI::Loader::mysql redefind methods export for DBD::Multiplex.

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

See

L<Class::DBI::Loader::mysql>

=head1 DESCRIPTION

Change:

-------------------------------------------------------

# Class::DBI::Loader::mysql

DBI->connect(@{$self->{_datasource}});

-------------------------------------------------------

TO

-------------------------------------------------------

# Class::DBI::Loader::Multiplex::mysql

my @dsn_master = $self->{'_get_master_datasource'}();

DBI->connect(@dsn_master);

-------------------------------------------------------

Class::DBI::Loader::mysql::_relationships {...} and Class::DBI::Loader::mysql::_tables {...}

ware corrected in this manner.

Maybe, Class::DBI::Loader::SUBCLASSES are also safe if it similarly corrects it.

=head1 METHODS

=over 4

=back

=head1 NOTE

=over 4

=back

=head1 MORE IMPLEMENTATIONS

If you have any idea / request for this module to add new subclass.

=head1 AUTHOR

Naoki URAI C<naokiurai@cpan.org>

=over 4

=back

=head1 LICENSE

=over 4

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=back

=head1 MAIN

=head1 SEE ALSO

=over 4

L<Class::DBI::Loader>, L<Class::DBI::Loader::mysql>

L<Class::DBI::Loader::Multiplex>, L<Class::DBI::Loader::Multiplex::mysql>

=back

=cut

1;
__END__
