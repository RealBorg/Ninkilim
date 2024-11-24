package Ninkilim::Controller::Root;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller' }

__PACKAGE__->config(namespace => '');

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    my $page = $c->req->param('page') || 1;
    $c->stash(next_page => $page + 1);
    $c->stash(previous_page => $page - 1) if $page > 1;
    my $postings_rs = $c->model('DB')->resultset('Posting')->search(
        {
            -and => [
                text => { -not_like => 'RT%' },
                text => { -not_like => '@%' },
                parent => undef,
            ],
        },
        {
            order_by => {'-desc' => 'date'},
            rows => 10,
            page => $page,
            prefetch => 'medias',
        }
    );
    for my $q (split(/\s+/, $c->req->param('q') || '')) {
        $q =~ s/%/%%/;
        $q = "%$q%";
        $postings_rs = $postings_rs->search(
            {
                text => { -ilike => $q },
            }
        );
    }
    my $postings;
    for my $posting ($postings_rs->all()) {
        my $medias = $posting->medias;
        my $source = $posting->source;
        $posting = {
            id => $posting->id,
            date => $posting->date->iso8601,
            text => $posting->text,
            lang => $posting->lang,
            parent => $posting->parent,
        };
        $posting->{text} =~ s/(https?:\/\/[^\s]+)/<a href="$1">$1<\/a>/;
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
    if ($c->req->param('format') eq 'json') {
        $c->stash(json_data => $postings);
        $c->forward('View::JSON');
    } else {
        $c->stash(postings => $postings);
        $c->stash(template => 'index.tt2');
        $c->forward('View::HTML');
    }
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
sub end : ActionClass('RenderView') {}

__PACKAGE__->meta->make_immutable;

1;
