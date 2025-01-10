#!/usr/bin/perl
use IO::Socket::IP;
use POSIX;
use Time::HiRes;

use FindBin qw/$RealBin/;
use lib "$RealBin/../lib";
use Ninkilim::Model::DNS;

use strict;
use warnings;

while (1) {
    my $server_socket = IO::Socket::IP->new(
        Listen => 1,
        LocalAddr => '[::]',
        LocalPort => 53,
        Proto => 'tcp',
        ReuseAddr => 1,
        ReusePort => 1,
    );
    unless ($server_socket) {
        warn "Couldn't create socket: $!\n";
        sleep 6;
        next;
    }

    while (my $client_socket = $server_socket->accept) {
        STDOUT->printf(
            "%s %s %s\n",
            $0, 
            POSIX::strftime('%Y-%m-%dT%H:%M:%S', gmtime(time)), 
            $client_socket->peerhost,
        );
        my $timeout = Time::HiRes::time() + 1;
        my $query = '';
        $client_socket->blocking(0);
        while (Time::HiRes::time() < $timeout) {
            my $buf = '';
            $client_socket->sysread($buf, 1500);
            if (length($buf) > 0) {
                $query .= $buf;
                if (length($query) >= 2) {
                    my $length = unpack('n', substr($query, 0, 2));
                    if (length($query) == $length + 2) {
                        $query = substr($query, 2);
                        last;
                    }
                }
            }
            Time::HiRes::sleep(0.1);
        }
        my $reply = Ninkilim::Model::DNS->reply("$RealBin/../root/dns.txt", $query);
        if ($reply) {
            $reply = $reply->data;
            $client_socket->print(pack('n', length($reply)), $reply);
        }
        $client_socket->close;
    }
}
