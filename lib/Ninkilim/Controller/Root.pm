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
    my $postings = $c->model('DB')->resultset('Posting')->search(
        {
            -and => [
                full_text => { -not_like => 'RT%' },
                full_text => { -not_like => '@%' },
                in_reply_to => undef,
            ],
        },
        {
            order_by => {'-desc' => 'created_at'},
            rows => 10,
            page => $page,
            prefetch => 'medias',
        }
    );
    for my $q (split(/\s+/, $c->req->param('q') || '')) {
        $q =~ s/%/%%/;
        $q = "%$q%";
        $postings = $postings->search(
            {
                full_text => { -ilike => $q },
            }
        );
    }
    $c->stash(postings => [ $postings->all() ]);
    $c->stash(template => 'index.tt2');
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
