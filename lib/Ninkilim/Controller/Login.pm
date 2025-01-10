package Ninkilim::Controller::Login;
use DateTime;
use Digest::SHA;
use Moose;
use namespace::autoclean;
use Sys::Hostname;
use Ninkilim::Email;

use constant {
    CHARSET => [ '0'..'9', 'a'..'z', 'A'..'Z' ],
};

BEGIN { extends 'Catalyst::Controller'; }

sub begin :Private {
    my ( $self, $c ) = @_;
}

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    if (my $email = $c->req->param('email')) {
        my $email_hash = Digest::SHA::sha512_base64($email);
        if (my $user = $c->model('DB')->resultset('User')->find({ email => $email_hash })) {
            my $token;
            for (my $i = 0; $i < 32; $i++) {
                $token .= CHARSET->[int(rand(scalar(@{CHARSET()})))];
            }
            $token = $c->model('DB')->resultset('LoginToken')->create(
                {
                    user_id => $user->id,
                    token => $token,
                    created => DateTime->now(),
                }
            );
            my $uri = $c->uri_for('/login', $token->token);
            $uri->host(hostname());
            $uri = $uri->as_string;
            my $email = Ninkilim::Email->new(
                To => $email,
                Subject => $c->uri_for('/'),
                Type => 'text/plain',
                Data => $uri,
            );
            $email->send;
            if ($token) {
                $c->stash->{'message'} = 'A login token has been sent to your e-mail address';
            }
        }
    }
}

sub login :Path :Args(1) {
    my ( $self, $c, $token ) = @_;

    my $rs = $c->model('DB')->resultset('LoginToken');
    $rs->search(
        {
            created => { '<' => DateTime->now->add(hours => -1) },
        }
    )->delete;
    $token = $rs->find(
        {
            token => $token,
        }
    );
    if ($token) {
        $c->session->{user_id} = $token->user_id;
        $token->delete;
        $c->stash->{'message'} = 'Login successful';
    } else {
        $c->stash->{'message'} = 'Login failed - token already used or expired';
    }
    $c->stash->{'template'} = 'login/index.tt2';
}

sub end :Private {
    my ( $self, $c ) = @_;

    $c->detach('View::HTML');
}

__PACKAGE__->meta->make_immutable;

1;
