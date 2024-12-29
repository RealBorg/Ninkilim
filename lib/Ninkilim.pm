package Ninkilim;
use Moose;
use namespace::autoclean;
use POSIX;

use Catalyst::Runtime 5.80;

use Catalyst qw/
    -Debug
    ConfigLoader
    Session
    Session::State::Cookie
    Session::Store::DBIC
/;

extends 'Catalyst';

our $VERSION = '0.01';

__PACKAGE__->config(
    name => 'Ninkilim',
    # Disable deprecated behavior needed by old applications
    disable_component_resolution_regex_fallback => 1,
    enable_catalyst_header => 1, # Send X-Catalyst header
    encoding => 'UTF-8', # Setup request decoding and response encoding
    using_frontend_proxy => 1,
    'Plugin::Session' => {
        dbic_class => 'DB::Session',
        expires => 60*60,
    },
    'View::HTML' => {
        TEMPLATE_EXTENSION => '.tt2',
    },
);
$ENV{TZ} = 'UTC';
POSIX::tzset();
$ENV{LC_ALL} = 'POSIX';
POSIX::setlocale(POSIX::LC_ALL, $ENV{LC_ALL});

__PACKAGE__->setup();

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
