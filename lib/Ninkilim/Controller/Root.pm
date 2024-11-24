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

sub posting :Local {
    my ( $self, $c ) = @_;

    my $resultset = $c->stash->{'resultset'};
    my $postings;
    if (my $id = $c->req->param('id')) {
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
    } else {
        $c->stash->{'postings'} = [];
    }
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

sub default :Path {
    my ( $self, $c ) = @_;

    $c->response->body( 'Page not found' );
    $c->response->status(404);
}

sub forbidden :Private {
    my ( $self, $c ) = @_;

    $c->response->status(403);
    $c->response->body('Forbidden');
}

sub end :Private {
    my ( $self, $c ) = @_;

    delete $c->stash->{'resultset'};

    my $postings;
    for my $posting (@{$c->stash->{'postings'}}) {
        my $medias = $posting->medias;
        my $source = $posting->source;
        $posting = {
            id => $posting->id,
            date => $posting->date->iso8601,
            text => $posting->text,
            lang => $posting->lang,
            parent => $posting->parent,
        };
        $posting->{text} =~ s/(https?:\/\/[^\s]+)/<a href="$1">$1<\/a>/g;
        $posting->{source} = {
            id => $source->id,
            name => $source->name,
            description => $source->description,
        };
        for my $media ($medias->all) {
            push @{$posting->{medias}}, {
                id => $media->id,
                filename => $media->filename,
                type => $media->type,
            };
        }
        push @{$postings}, $posting;
    }
    $c->stash->{'postings'} = $postings;

    my $format = $c->req->param('format') || '';
    if ($format eq 'json') {
        $c->stash->{'json_data'} = $c->stash->{'postings'};
        $c->forward('View::JSON');
    } else {
        $c->stash->{'template'} = 'index.tt2';
        $c->forward('View::HTML');
    }
}

__PACKAGE__->meta->make_immutable;

1;
