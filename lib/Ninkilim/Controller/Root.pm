package Ninkilim::Controller::Root;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller' }

__PACKAGE__->config(namespace => '');

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
    my $postings = $resultset->search(
        {
            -and => [
                text => { -not_like => '@%' },
                parent => undef,
            ],
        }
    );
    $c->stash->{'postings'} = [ $postings->all() ];
}

sub posting :Local :Args(1) {
    my ( $self, $c, $id ) = @_;

    my $resultset = $c->stash->{'resultset'};
    my $postings;
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
    $c->stash->{'postings'} = $postings;
}

sub search :Local {
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
    $c->stash->{'postings'} = [ $resultset->all() ];
}

sub sitemap :Local :Args(1) {
    my ( $self, $c, $page ) = @_;

    $c->stash->{urlset} = {
        url => [],
        xmlns => 'http://www.sitemaps.org/schemas/sitemap/0.9',
    };
    $c->stash->{xmlopts} = {
        RootName => undef,
        XMLDecl => '<?xml version="1.0" encoding="UTF-8"?>', 
        NoAttr => 0, 
        AttrIndent => 1,
        #KeepRoot => 1,
    };
    $c->req->params->{format} = 'xml';
    my $resultset = $c->stash->{'resultset'};
    $resultset = $resultset->search(
        {},
        {
            columns => [ qw/id/ ],
            rows => 25_000,
            page => $page,
            prefetch => undef,
        }
    );
    for my $row ($resultset->all()) {
        push @{$c->stash->{urlset}->{url}}, { loc => [ $c->uri_for('/posting/'.$row->id)->as_string ] };
    }
    delete $c->stash->{next_page};
    delete $c->stash->{previous_page};
    delete $c->stash->{postings};
}

sub default :Path {
    my ( $self, $c ) = @_;

    $c->response->status(404);
}

sub forbidden :Private {
    my ( $self, $c ) = @_;

    $c->response->status(403);
}

sub end :Private {
    my ( $self, $c ) = @_;

    delete $c->stash->{'resultset'};

    my $postings = $c->stash->{postings};
    delete $c->stash->{postings};
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
        $posting->{date} = $posting->{date}->iso8601;
        $posting->{text} =~ s/(https?:\/\/[^\s]+)/<a href="$1">$1<\/a>/g;
        push @{$c->stash->{postings}}, $posting;
    }

    my $format = $c->req->param('format') || '';
    if ($format eq 'json') {
        $c->forward('View::JSON');
    } elsif ($format eq 'xml') {
        $c->forward('View::XML');
    } else {
        $c->stash->{'template'} = 'index.tt2' unless $c->stash->{'template'};
        $c->forward('View::HTML');
    }
}

__PACKAGE__->meta->make_immutable;

1;
