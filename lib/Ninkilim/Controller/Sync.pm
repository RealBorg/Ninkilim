package Ninkilim::Controller::Sync;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

sub begin :Private {
    my ( $self, $c ) = @_;

    $c->stash->{'format'} = 'html';
    $c->stash->{'resultset'} = $c->model('DB')->resultset('Peer');
}

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    my $rs = $c->stash->{'resultset'};
    if ($c->user && $c->req->method eq 'POST') {
        if ($c->req->param('delete')) {
            $rs->search(
                {
                    owner => $c->user->id,
                    url => $c->req->param('url'),
                }
            )->delete;
        } elsif ($c->req->param('update')) {
            $rs->search(
                {
                    owner => $c->user->id,
                    url => $c->req->param('url'),
                }
            )->update(
                {
                    url => $c->req->param('newurl'),
                    last_id => $c->req->param('last_id'),
                }
            );
        } elsif ($c->req->param('create')) {
            $rs->create(
                {
                    url => $c->req->param('url'),
                    owner => $c->user->id,
                    last_id => $c->req->param('last_id'),
                }
            );
        }
    }
    $c->stash->{'data'}->{'peers'} = [ $rs->search()->all() ];
    $self->finalize($c);
}

sub finalize {
    my ( $self, $c ) = @_;

    for my $peer (@{$c->stash->{'data'}->{'peers'}}) {
        $peer = { $peer->get_columns };
    }
}

__PACKAGE__->meta->make_immutable;

1;
