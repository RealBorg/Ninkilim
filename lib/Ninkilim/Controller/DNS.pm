package Ninkilim::Controller::DNS;
use Moose;
use namespace::autoclean;

use File::Slurp;
use List::Util;
use MIME::Base64;
use Net::DNS;
use Ninkilim::Model::DNS;

BEGIN { extends 'Catalyst::Controller'; }

sub index :Path :Args(0) {
    my ($self, $c) = @_;

    $c->stash->{data}->{dns} = Ninkilim::Model::DNS->load_records($c->path_to(qw/root dns.txt/));
}

sub query :Path(/dns-query) :Args(0) {
    my ($self, $c) = @_;

    $c->log->debug(
        join(
            ' ',
            __PACKAGE__,
            POSIX::strftime('%Y-%m-%dT%H:%M:%S', gmtime(time)),
            $c->req->address,
        )
    );
    my $query;
    if ($c->req->method eq 'GET') {
        $query = decode_base64($c->req->param('dns'));
    } elsif ($c->req->method eq 'POST') {
        $query = File::Slurp::read_file($c->req->body);
    }

    my $reply = Ninkilim::Model::DNS->reply($c->path_to(qw/root dns.txt/), $query);
    if ($reply) {
        $reply = $reply->data;
        $c->res->header('Content-Type' => 'application/dns-message');
        $c->res->header('Content-Length' => length($reply));
        $c->res->body($reply);
    }
}

__PACKAGE__->meta->make_immutable;

1;
