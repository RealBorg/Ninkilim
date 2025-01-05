package Ninkilim::Script::Checkit;
use Moose;
use namespace::clean -except => [ 'meta' ];

with 'Catalyst::ScriptRole';

use Ninkilim;
use POSIX;
use Time::HiRes;

use strict;
use warnings;

sub run {
    my $self = shift;

    my $model = Ninkilim->model('Checkit');
    while (1) {
        my $nextrun = Time::HiRes::time + 5 * 60;
        $model->run_checks;
        Ninkilim->log->debug('Next run at '.POSIX::strftime('%Y-%m-%dT%H:%M:%S', gmtime($nextrun)));
        my $sleep = $nextrun - Time::HiRes::time;
        Time::HiRes::sleep($sleep) if $sleep > 0;
    }
}

__PACKAGE__->meta->make_immutable;
1;
