package Ninkilim::View::YAML;
use Moose;
use namespace::autoclean;
use Encode;
use YAML::XS;

extends 'Catalyst::View';

use strict;
use warnings;
use bytes;

sub process {
    my ($self, $c) = @_;

    my $data = $c->stash->{'data'};
    $data = Dump($data);
    $data = decode('utf8', $data);
    $c->res->header('Content-Type', 'text/yaml');
    $c->res->header('Content-Length', length($data));
    $c->res->body($data);

    return 1;
}

__PACKAGE__->meta->make_immutable;

1;
