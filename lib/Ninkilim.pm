package Ninkilim;
use Moose;
use namespace::autoclean;

use Catalyst::Runtime 5.80;

use Catalyst qw/
    -Debug
    ConfigLoader
    Session
    Session::State::Cookie
    Session::Store::DBIC
    Static::Simple
/;

extends 'Catalyst';

our $VERSION = '0.01';

__PACKAGE__->config(
    name => 'Ninkilim',
    # Disable deprecated behavior needed by old applications
    disable_component_resolution_regex_fallback => 1,
    enable_catalyst_header => 1, # Send X-Catalyst header
    encoding => 'UTF-8', # Setup request decoding and response encoding
    'Plugin::Static::Simple' => {
        ignore_extensions => [],
        include_path => [ __PACKAGE__->config->{root}.'/static' ],
        dirs => [ 'static' ],
    },
    'Plugin::Session' => {
        dbic_class => 'DB::Session',
        expires => 60*60,
    },
    'View::HTML' => {
        TEMPLATE_EXTENSION => '.tt2',
    },
);

__PACKAGE__->setup();

sub uri_for {
    my ($self, $path, @args) = @_;

    my $uri = $self->SUPER::uri_for($path, @args);
    if (my $scheme = $self->req->header('X-Forwarded-Proto')) {
        $uri->scheme($scheme);
    }
    if (my $port = $self->req->header('X-Forwarded-Port')) {
        if ($uri->scheme eq 'http' && $port == 80) {
            $uri->port(undef);
        } elsif ($uri->scheme eq 'https' && $port == 443) {
            $uri->port(undef);
        } else {
            $uri->port($port);
        }
    }
    return $uri;
}

sub user {
    my ($self) = @_;

    my $user;
    if ($self->sessionid) {
        if (my $user_id = $self->session->{user_id}) {
            $user = $self->model('DB')->resultset('User')->find({ id => $user_id });
        }
    }
    return $user;
}

1;
