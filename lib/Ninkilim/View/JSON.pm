package Ninkilim::View::JSON;
use Moose;
use namespace::autoclean;
use JSON;

extends 'Catalyst::View';

use strict;
use warnings;

sub process {
    my ($self, $c) = @_;

    my $data = $c->stash->{'data'};
    my $json = JSON->new();
    $data = $json->encode($data);
    $c->response->content_type('text/json');
    $c->res->body($data);

    return 1;
}

1;
