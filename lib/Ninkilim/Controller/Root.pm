package Ninkilim::Controller::Root;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller' }

__PACKAGE__->config(namespace => '');

use constant {
    VIEWS => {
        '' => 'View::HTML',
        html => 'View::HTML',
        json => 'View::JSON',
        none => undef,
        xml => 'View::XML',
        yaml => 'View::YAML',
    },
};

sub default :Path {
    my ( $self, $c ) = @_;

    my $static = $c->controller('Root::Static');
    $static->index($c);
}

sub forbidden :Private {
    my ( $self, $c ) = @_;

    $c->stash->{'data'} = 'FORBIDDEN';
    $c->stash->{'template'} = 'error.tt2';
    $c->response->status(403);
}

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    my $postings = $c->controller('Postings');
    $postings->begin($c);
    $postings->index($c);
    $c->stash->{'template'} = 'postings/index.tt2';
}

sub methodnotallowed :Local {
    my ( $self, $c ) = @_;

    $c->stash->{'data'} = 'METHOD NOT ALLOWED';
    $c->stash->{'template'} = 'error.tt2';
    $c->res->status(405);
}

sub notfound :Local {
    my ( $self, $c ) = @_;

    $c->stash->{'data'} = 'NOT FOUND';
    $c->stash->{'template'} = 'error.tt2';
    $c->res->status(404);
}

sub notmodified :Local {
    my ( $self, $c ) = @_;

    $c->stash->{'format'} = 'none';
    $c->res->status(304);
}

sub search :Local :Args(0) {
    my ( $self, $c ) = @_;

    my $postings = $c->controller('Postings');
    $postings->begin($c);
    $postings->search($c);
    $c->stash->{'template'} = 'postings/search.tt2';
}

sub end :Private {
    my ( $self, $c ) = @_;

    unless ($c->res->body) {
        my $format = $c->stash->{'format'} || $c->req->param('format') || 'html';
        my $view = VIEWS->{$format};
        if ($view) {
            $c->forward($view);
        }
    }
}

__PACKAGE__->meta->make_immutable;

1;
