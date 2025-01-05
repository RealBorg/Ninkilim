package Ninkilim::Controller::Checkit;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    $c->res->header(Refresh => 5 * 60);
    $c->stash->{'data'} = $c->model('Checkit')->get_results;
}

__PACKAGE__->meta->make_immutable;

1;
