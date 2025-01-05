package Ninkilim::Script::DNS::UDP;
use Moose;
use namespace::clean -except => [ 'meta' ];

with 'Catalyst::ScriptRole';

use IO::Socket::IP;
#use Socket;
use Ninkilim;

use strict;
use warnings;

sub run {
    my $self = shift;

    my $model = Ninkilim->model('DNS');
    while (1) {
        my $socket = IO::Socket::IP->new(
            Family => AF_INET6,
            LocalAddr => '[::]',
            LocalPort => 53,
            Proto => 'udp',
            ReuseAddr => 1,
            ReusePort => 1,
        );
        unless ($socket) {
            warn "Couldn't create UDP socket: $@\n";
            sleep 6;
            next;
        }

        my $query;
        while ($socket->recv($query, 15000)) {
            Ninkilim->log->debug(
                sprintf(
                    "%s %s %s", 
                    __PACKAGE__, 
                    POSIX::strftime('%Y-%m-%dT%H:%M:%S', gmtime(time)), 
                    $socket->peerhost,
                )
            );
            my $reply = $model->reply($socket->peerhost, $query);
            if ($reply) {
                $reply->truncate(1452);
                $socket->send($reply->data);
            }
        }
    }
}

__PACKAGE__->meta->make_immutable;
1;

