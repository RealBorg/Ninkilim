package Ninkilim::Controller::Postings;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

use strict;
use warnings;

sub begin :Private {
    my ( $self, $c ) = @_;

    my $page = $c->req->param('page') || 1;
    $c->stash->{'next_page'} = $page + 1;
    $c->stash->{'previous_page'} = $page - 1 if $page > 1;

    my $resultset = $c->model('DB')->resultset('Posting')->search(
        {
            text => { -not_like => 'RT%' },
        },
        {
            order_by => {'-desc' => 'date'},
            rows => 10,
            page => $page,
            prefetch => 'medias',
        }
    );
    $c->stash->{'resultset'} = $resultset;
}

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    my $resultset = $c->stash->{'resultset'};
    my $postings = [];
    $postings = $resultset->search(
        {
            -and => [
                text => { -not_like => '@%' },
                parent => undef,
            ],
        }
    );
    $postings = [ $postings->all() ];
    $c->stash->{'data'}->{'postings'} = $postings;
}

sub create :Local :Args(0) {
    my ( $self, $c, $id ) = @_;
}

sub posting :Path :Args(1) {
    my ( $self, $c, $id ) = @_;

    my $resultset = $c->stash->{'resultset'};
    my $postings = [];
    my $posting = $resultset->find({
        id => $id,
    });
    if ($posting) {
        push @{$postings}, $posting;
    }
    for (my $i = 0; $i < scalar(@{$postings}); $i++) {
        push @{$postings}, $resultset->search({
            parent => $postings->[$i]->id,
        })->all;
    }
    $c->stash->{'data'}->{'postings'} = $postings;
    $c->stash->{template} = 'postings/index.tt2';
}

sub search :Local :Args(0) {
    my ( $self, $c ) = @_;

    my $resultset = $c->stash->{'resultset'};
    for my $q (split(/\s+/, $c->req->param('q') || '')) {
        $q =~ s/%/%%/;
        $q = "%$q%";
        $resultset = $resultset->search(
            {
                text => { -ilike => $q },
            }
        );
    }
    $c->stash->{'data'}->{'postings'} = [ $resultset->all() ];
    $c->stash->{'template'} = 'postings/index.tt2';
}

sub sitemap :Local :Args(1) {
    my ( $self, $c, $page ) = @_;

    my $resultset = $c->stash->{'resultset'}->search(
        {},
        {
            columns => [ qw/id/ ],
            rows => 25_000,
            page => $page,
            prefetch => undef,
        }
    );
    my $url = [];
    for my $row ($resultset->all()) {
        push @{$url}, { loc => [ $c->uri_for('/postings/'.$row->id)->as_string ] };
    }
    $c->stash->{'data'}->{'urlset'} = {
        url => $url,
        xmlns => 'http://www.sitemaps.org/schemas/sitemap/0.9',
    };
    $c->stash->{'xmlopts'} = {
        RootName => undef,
        XMLDecl => '<?xml version="1.0" encoding="UTF-8"?>', 
        NoAttr => 0, 
        AttrIndent => 1,
        #KeepRoot => 1,
    };
    $c->req->params->{'format'} = 'xml';
}

sub end :Private {
    my ( $self, $c ) = @_;

    my $postings = $c->stash->{'data'}->{'postings'};
    delete $c->stash->{'data'}->{'postings'};
    for my $posting (@{$postings}) {
        my $medias = [ $posting->medias->all ];
        for my $media (@{$medias}) {
            $media = { $media->get_inflated_columns };
            delete $media->{posting};
        }
        my $author = $posting->author;
        $author = { $author->get_inflated_columns };
        delete $author->{email};
        $posting = {
            $posting->get_inflated_columns,
            author => $author,
            medias => $medias,
        };
        $posting->{parent} ||= 0;
        $posting->{date} = $posting->{date}->iso8601;
        $posting->{text} =~ s/(https?:\/\/[^\s]+)/<a href="$1">$1<\/a>/g;
        push @{$c->stash->{data}->{postings}}, $posting;
    }

    my $format = $c->req->param('format') || '';
    if ($format eq 'json') {
        $c->forward('View::JSON');
    } elsif ($format eq 'xml') {
        $c->forward('View::XML');
    } else {
        $c->forward('View::HTML');
    }
}

__PACKAGE__->meta->make_immutable;

1;
