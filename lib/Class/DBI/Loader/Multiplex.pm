package Class::DBI::Loader::Multiplex;

use warnings;
use strict;

use base qw/ Class::DBI::Loader::Generic /;
use vars qw/ $VERSION /;
use DBI;
use Carp;

$VERSION = '0.01';

sub new {
    my ($class, %args) = @_;
    if($args{debug}){
        no strict 'refs';
        *{"$class\::debug"} = sub { 1 };
    }
    my $additional = $args{additional_classes} || [];
    $additional = [$additional] unless ref $additional eq 'ARRAY';
    my $additional_base = $args{additional_base_classes} || [];
    $additional_base = [$additional_base]
      unless ref $additional_base eq 'ARRAY';
    my $left_base = $args{left_base_classes} || [];
    $left_base = [$left_base] unless ref $left_base eq 'ARRAY';
    my $self = bless {
        _datasource =>
            [
                $args{dsn},
                $args{user},
                $args{password},
                $args{options}
            ],
        _namespace       => $args{namespace},
        _additional      => $additional,
        _additional_base => $additional_base,
        _left_base       => $left_base,
        _constraint      => $args{constraint} || '.*',
        _exclude         => $args{exclude},
        _relationships   => $args{relationships},
        _inflect         => $args{inflect},
        _require         => $args{require},
        _require_warn    => $args{require_warn},
        CLASSES          => {},
    }, $class;
    warn qq/\### START Class::DBI::Loader dump ###\n/ if $self->debug;
    $self->_extension_meth_in_new;
    $self->_load_classes;
    $self->_relationships if $self->{_relationships};
    warn qq/\### END Class::DBI::Loader dump ###\n/ if $self->debug;

    # disconnect to avoid confusion.
    foreach my $table ($self->tables) {
        $self->find_class($table)->db_Main->disconnect;
    }
    return $self;
}

sub _extension_meth_in_new {
    my $self = shift;
    $self->{'_get_master_datasource'} = $self->_get_master_datasource;
    my $plugin_name   = $self->_get_dbi_name;
    my $plugin_loader = sprintf('Class::DBI::Loader::Multiplex::PluginLoader \'%s\'', $plugin_name);
    eval qq/use $plugin_loader/;
    die Carp::croak(sprintf('Couldn\'t require plugin %s::%s', __PACKAGE__, $plugin_name, $@)) if $@;
    return;
}

sub _get_dbi_name {
    my $self = shift;
    my ($dsn) = $self->{'_get_master_datasource'}();
    my ($dbi) = $dsn =~ m/^dbi:(\w*?)(?:\((.*?)\))?:/i;
    $dbi = 'SQLite' if $dbi eq 'SQLite2';
    return $dbi || '';
}

sub _db_class {
    my $self = shift;
    my $dbi = $self->_get_dbi_name;
    my $dbi_impl = "Class::DBI::" . $dbi;
    eval qq/use $dbi_impl/;
    die Carp::croak(sprintf('Couldn\'t require loader class %s %s', $dbi_impl, $@)) if $@;
    return $dbi_impl;
}

sub _get_master_datasource{
    my $self = shift;
    my @datasource = ();
    return sub{
        return @datasource if scalar @datasource;

        my $mx_master_id = '';
        EXIT:
        for my $ds_attr (@{$self->{_datasource}}){
            next if lc(ref($ds_attr)) ne 'hash';
            $mx_master_id = sprintf('mx_id=%s',$ds_attr->{mx_master_id})
                if $ds_attr->{mx_master_id};
            if(lc ref($ds_attr->{mx_dsns}) eq 'array'){
                for my $dsn (@{$ds_attr->{mx_dsns}}){
                    next if $dsn !~ /;?$mx_master_id;?/i;
                    push @datasource, $dsn;
                    last EXIT;
                }
            }
        }
        # user
        push @datasource, $self->{_datasource}[1];
        # password
        push @datasource, $self->{_datasource}[2];
        return @datasource;
    };
}

=head1 NAME

Class::DBI::Loader::Multiplex - Bridge of Class::DBI::Loader and DBD::Multiplex.

=head1 VERSION

Version 0.01


=head1 SYNOPSIS

  For example, replicated mysql.

  use Class::DBI::Loader;

  # $loader is a Class::DBI::Loader::Multiplex

  my $loader = Class::DBI::Loader->new(
      dsn                 => 'dbi:Multiplex:',
      user                => 'root',
      password            => '',
      options             => {
          mx_dsns => [
              'dbi:mysql:dbName:masterHost;mx_id=masterID',
              'dbi:mysql:dbName:slaveHost;mx_id=slaveID',
          ],
          mx_master_id    => 'masterID',
          mx_connect_mode => 'ignore_errors',
          mx_exit_mode    => 'first_success',
      },
      relationships => 1
  );
  ...

  # for Catalyst::Model::CDBI (app.yml)

  Model::CDBI:
    dsn:      'dbi:Multiplex:'
    user:     'root'
    password: ''
    options:
      mx_dsns:
        - 'dbi:mysql:dbName:masterHost;mx_id=masterID'
        - 'dbi:mysql:dbName:slaveHost;mx_id=slaveID'
      mx_master_id:    'masterID'
      mx_connect_mode: 'ignore_errors'
      mx_exit_mode:    'first_success'
    relationships: 1

=head1 DESCRIPTION

For now, this module supports default MySQL only.

But other DBMS implementation is very easyly. Because Class::DBI::Loader and DBD::Multiplex supports many DBMS.

I am waiting for your help and please teach me more better method also. :-)

See

L<Class::DBI::Loader>, L<Class::DBI::Loader::mysql>, L<DBD::Multiplex>,

L<Class::DBI::Loader::Multiplex>,L<Class::DBI::Loader::Multiplex::PluginLoader>,L<Class::DBI::Loader::Multiplex::mysql>,

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

=item * Search CPAN

L<http://search.cpan.org/dist/Class-DBI-Loader-Multiplex>

=back

=head1 LICENSE

=over 4

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=back

=head1 MAIN

=head1 SEE ALSO

=over 4

L<Class::DBI::Loader>, L<Class::DBI::Loader::mysql>, L<DBD::Multiplex>

L<Class::DBI::Loader::Multiplex>, L<Class::DBI::Loader::Multiplex::PluginLoader>

L<Class::DBI::Loader::Multiplex::mysql>

=back

=cut

1; # End of Class::DBI::Loader::Multiplex
