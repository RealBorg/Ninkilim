package Ninkilim::Controller::Users;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

sub begin :Private {
    my ( $self, $c ) = @_;

    my $rs = $c->model('DB')->resultset('User');
    $c->stash->{'resultset'} = $rs;
}

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    my $rs = $c->stash->{'resultset'}->search(
        {
        },
        {
            order_by => { '-desc' => 'username' },
        }
    );
    $c->stash->{'data'}->{'users'} = [ $rs->all ];
    $self->finish($c);
}

sub user :Path :Args(1) {
    my ( $self, $c, $username ) = @_;

    my $user = $c->stash->{'resultset'}->find({ username => $username });
    my $postings = $c->controller('Postings');
    $postings->begin($c);
    $c->stash->{'resultset'} = $c->stash->{'resultset'}->search(
        author => $user->id,
    );
    $postings->index($c);
    $c->stash->{'data'}->{'users'} = [ $user ];
    $c->stash->{'title'} = sprintf("%s on %s", $user->displayname, $c->uri_for('/')->host);
    $self->finish($c);
}

sub finish :Private {
    my ( $self, $c ) = @_;

    my $users = $c->stash->{'data'}->{'users'};
    for my $user (@{$users}) {
        $user = { $user->get_inflated_columns };
    }
}

__PACKAGE__->meta->make_immutable;

1;
