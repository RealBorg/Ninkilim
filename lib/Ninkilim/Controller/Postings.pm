package Ninkilim::Controller::Postings;
use Moose;
use namespace::autoclean;
use DateTime;
use Text::MultiMarkdown qw/markdown/;
use Data::Dumper;

BEGIN { extends 'Catalyst::Controller'; }

use strict;
use warnings;

sub begin :Private {
    my ( $self, $c ) = @_;

    my $page = abs(int($c->req->param('page') || 1));
    $c->stash->{'page'}->{'current'} = $page;
    $c->stash->{'page'}->{'next'} = $page + 1;
    $c->stash->{'page'}->{'previous'} = $page - 1 if $page > 1;

    my $rows = abs(int($c->req->param('rows') || '10'));
    $rows = 10 if $rows > 100;

    my $order_by = { -desc => 'date' };
    if (($c->req->param('sort') || 'desc') eq 'asc') {
        $order_by = 'date',
    }

    my $min_id = abs(int($c->req->param('min_id') || 0));

    my $resultset = $c->model('DB')->resultset('Posting')->search(
        {
            'id' => { '>' => $min_id },
        },
        {
            order_by => $order_by,
            rows => $rows,
            page => $page,
        }
    );
    unless ($c->req->param('include_rt')) {
        $resultset = $resultset->search(
            {
                text => { -not_like => 'RT%' },
            },
            {}
        );
    }
    $c->stash->{'resultset'} = $resultset;
}

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    my $resultset = $c->stash->{'resultset'};
    unless ($c->req->param('include_replies')) {
        $resultset = $resultset->search(
            {
                -and => [
                    text => { -not_like => '@%' },
                    parent => undef,
                ],
            }
        );
    }
    my $postings = [ $resultset->all() ];
    $c->stash->{'title'} = $c->uri_for('/')->host . '/' . $c->stash->{'page'}->{'current'};
    $c->stash->{'data'}->{'postings'} = $postings;
    $self->finish($c);
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
        my $title = $posting->text;
        $title = [ split(/ /, $title) ];
        $title = join(' ', @{$title}[0..8]);
        $title = $posting->author->displayname . ': ' . $title . '...';
        $c->stash->{'title'} = $title;
    }
    for (my $i = 0; $i < scalar(@{$postings}); $i++) {
        push @{$postings}, $resultset->search({
            parent => $postings->[$i]->id,
        })->all;
    }
    $c->stash->{'data'}->{'postings'} = $postings;
    $self->finish($c);
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
    $c->stash->{'title'} = 'Search: ' . $c->req->param('q');
    $c->stash->{'data'}->{'postings'} = [ $resultset->all() ];
    $self->finish($c);
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
    $c->stash->{'format'} = 'xml';
}

sub finish :Private {
    my ( $self, $c ) = @_;

    my $postings = $c->stash->{'data'}->{'postings'};
    for my $posting (@{$postings}) {
        my $medias = [ $posting->medias->all ];
        for my $media (@{$medias}) {
            $media = { 
                $media->get_columns,
            };
            delete $media->{posting};
            $media->{url} = ''.$c->uri_for('/media', $media->{filename});
        }
        my $author = $posting->author;
        $author = { $author->get_columns };
        delete $author->{email};
        $posting = {
            $posting->get_columns,
            id => ''.$posting->id,
            author => $author,
            medias => $medias,
        };
        $posting->{parent} ||= 0;
        $posting->{'date'} =~ s/(\d{4}-\d{2}-\d{2}) (\d{2}:\d{2}:\d{2})([+-]\d{2})/$1T$2/;
    }
    $c->stash->{'markdown'} = sub {
        my $text = shift;
        $text =~ s/(https?:\/\/[^\s]+)/[$1]($1)/g;
        $text = Text::MultiMarkdown::markdown($text);
        return $text;
    };
}

__PACKAGE__->meta->make_immutable;

1;
