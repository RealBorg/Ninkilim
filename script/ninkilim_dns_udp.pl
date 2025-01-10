#!/usr/bin/perl
use IO::Socket::IP;
use POSIX;

use FindBin qw/$RealBin/;
use lib "$RealBin/../lib";
use Ninkilim::Model::DNS;

use strict;
use warnings;

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
        STDOUT->printf(
            "%s %s %s\n",
            $0, 
            POSIX::strftime('%Y-%m-%dT%H:%M:%S', gmtime(time)), 
            $socket->peerhost,
        );
        my $reply = Ninkilim::Model::DNS->reply("$RealBin/../root/dns.txt", $query);
        if ($reply) {
            $reply->truncate(1452);
            $socket->send($reply->data);
        }
    }
}
