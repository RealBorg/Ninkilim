package Ninkilim::Model::DB;

use strict;
use base 'Catalyst::Model::DBIC::Schema';

__PACKAGE__->config(
    schema_class => 'Ninkilim::Schema',
    
    connect_info => {
        dsn => 'dbi:Pg:dbname=ninkilim',
        user => '',
        password => '',
    }
);

=head1 NAME

Ninkilim::Model::DB - Catalyst DBIC Schema Model

=head1 SYNOPSIS

See L<Ninkilim>

=head1 DESCRIPTION

L<Catalyst::Model::DBIC::Schema> Model using schema L<Ninkilim::Schema>

=head1 GENERATED BY

Catalyst::Helper::Model::DBIC::Schema - 0.65

=head1 AUTHOR

Thomas Zehetbauer

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
