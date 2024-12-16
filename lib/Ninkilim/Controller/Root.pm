package Ninkilim::Controller::Root;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller' }

__PACKAGE__->config(namespace => '');

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    $c->go('/postings/index');
}

sub default :Path {
    my ( $self, $c ) = @_;

    $c->res->body('NOT FOUND');
    $c->response->status(404);
}

sub forbidden :Private {
    my ( $self, $c ) = @_;

    $c->response->status(403);
}

sub search :Local :Args(0) {
    my ( $self, $c ) = @_;

    $c->go('/postings/search');
}

__PACKAGE__->meta->make_immutable;

1;
