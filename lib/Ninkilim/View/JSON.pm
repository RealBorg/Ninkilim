package Ninkilim::View::JSON;
use Moose;
use namespace::autoclean;
use JSON;

extends 'Catalyst::View';

use strict;
use warnings;
use bytes;

sub process {
    my ($self, $c) = @_;

    my $data = $c->stash->{'data'};
    my $json = JSON->new;
    $data = $json->encode($data);
    $c->res->header('Content-Type', 'text/json');
    $c->res->header('Content-Length', length($data));
    $c->res->body($data);

    return 1;
}

1;
