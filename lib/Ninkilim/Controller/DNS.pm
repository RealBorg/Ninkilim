package Ninkilim::Controller::DNS;
use Moose;
use namespace::autoclean;

use File::Slurp;
use List::Util;
use MIME::Base64;
use Net::DNS;

BEGIN { extends 'Catalyst::Controller'; }

sub query :Path(/dns-query) :Args(0) {
    my ($self, $c) = @_;

    my $query;
    if ($c->req->method eq 'GET') {
        $query = decode_base64($c->req->param('dns'));
    } elsif ($c->req->method eq 'POST') {
        $query = File::Slurp::read_file($c->req->body);
    }

    my $model = $c->model('DNS');
    my $reply = $model->reply($c->req->address, $query);
    if ($reply) {
        $reply = $reply->data;
        $c->res->header('Content-Type' => 'application/dns-message');
        $c->res->header('Content-Length' => length($reply));
        $c->res->body($reply);
    }
}

sub end :Private {
    my ( $self, $c ) = @_;
}

__PACKAGE__->meta->make_immutable;

1;
