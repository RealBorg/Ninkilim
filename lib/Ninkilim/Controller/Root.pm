package Ninkilim::Controller::Root;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller' }

__PACKAGE__->config(namespace => '');

sub begin :Private {
    my ( $self, $c ) = @_;

    my $format = $c->req->param('format') || '';
    if ($format eq 'json') {
        $c->stash->{'format'} = 'json';
    } elsif ($format eq 'xml') {
        $c->stash->{'format'} = 'xml';
    } elsif ($format eq 'yaml') {
        $c->stash->{'format'} = 'yaml';
    } else {
        $c->stash->{'format'} = 'html';
    }
}

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    my $postings = $c->controller('Postings');
    $postings->begin($c);
    $postings->index($c);
    $c->stash->{'template'} = 'postings/index.tt2';
}

sub default :Path {
    my ( $self, $c ) = @_;

    my $static = $c->controller('Root::Static');
    $static->index($c);
}

sub forbidden :Private {
    my ( $self, $c ) = @_;

    $c->stash->{'format'} = 'html';
    $c->response->status(403);
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
        my $format = $c->stash->{'format'};
        if ($format eq 'json') {
            $c->forward('View::JSON');
        } elsif ($format eq 'xml') {
            $c->forward('View::XML');
        } elsif ($format eq 'yaml') {
            $c->forward('View::YAML');
        } else {
            $c->forward('View::HTML');
        }
    }
}

__PACKAGE__->meta->make_immutable;

1;
