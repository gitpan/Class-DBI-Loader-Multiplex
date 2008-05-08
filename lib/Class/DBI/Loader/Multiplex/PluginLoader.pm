package Class::DBI::Loader::Multiplex::PluginLoader;

use strict;
use warnings;
use vars qw/ $VERSION /;
use Carp;

$VERSION = '0.01';

sub import {
    my $class       = shift;
    my @plugin_list = @_;
    my $pkg         = caller;

    for (@plugin_list){
        my $plugin = sprintf("%s::%s", $pkg, $_);
        eval qq/use $plugin/;
        die Carp::croak(sprintf('Couldn\'t require plugin %s %s', $plugin, $@)) if $@;
        for my $meth ($plugin->exports){
            eval{
                no strict 'refs';
                *{"$pkg\::$meth"} = \&$meth;
            };
            die Carp::croak(sprintf('Couldn\'t redefine method %s %s', "$pkg\::$meth", $@)) if $@;
        }
    }
    return;
}

=head1 NAME

Class::DBI::Loader::Multiplex::PluginLoader -  Loading Class::DBI::Loader::Multiplex::SUBCLASS from Master Datasource Name.

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

See

L<Class::DBI::Loader::Multiplex>


sub _extension_meth_in_new {

    my $self = shift;

    $self->{'_get_master_datasource'} = $self->_get_master_datasource;

    my $plugin_name   = $self->_get_dbi_name;

    my $plugin_loader = sprintf('Class::DBI::Loader::Multiplex::PluginLoader \'%s\'', $plugin_name);

    eval qq/use $plugin_loader/;

    die Carp::croak(sprintf('Couldn\'t require plugin %s::%s', __PACKAGE__, $plugin_name, $@)) if $@;

    return;

}

=head1 DESCRIPTION

=over 4

=back

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

L<Class::DBI::Loader::Multiplex>, L<Class::DBI::Loader::Multiplex::mysql>

=back

=cut

1;
__END__
