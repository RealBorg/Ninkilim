package Ninkilim::Script::DNS::TLS;
use Moose;
use namespace::clean -except => [ 'meta' ];

with 'Catalyst::ScriptRole';

use IO::Socket::SSL;
use Ninkilim;
use Time::HiRes;

use strict;
use warnings;

sub run {
    my $self = shift;

    while (1) {
        my $server_socket = IO::Socket::SSL->new(
            Listen => 1,
            LocalAddr => '[::]',
            LocalPort => 853,
            Proto => 'tcp',
            ReuseAddr => 1,
            ReusePort => 1,
            SSL_cert_file => '/media/sdc/etc/ssl/hostmaster.org/fullchain.pem',
            SSL_key_file => '/media/sdc/etc/ssl/hostmaster.org/privkey.pem',
            SSL_verify_mode => IO::Socket::SSL::SSL_VERIFY_NONE(),
        );
        unless ($server_socket) {
            warn "Couldn't create socket: $@ $!\n";
            sleep 6;
            next;
        }
        my $model = Ninkilim->model('DNS');

        while (my $client_socket = $server_socket->accept) {
            Ninkilim->log->debug(
                sprintf(
                    "%s %s %s", 
                    __PACKAGE__, 
                    POSIX::strftime('%Y-%m-%dT%H:%M:%S', gmtime(time)), 
                    $client_socket->peerhost,
                )
            );
            $client_socket->blocking(0);
            my $timeout = Time::HiRes::time() + 1;
            my $query = '';
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
            my $reply = $model->reply($client_socket->peerhost, $query);
            if ($reply) {
                $reply = $reply->data;
                $client_socket->print(pack('n', length($reply)), $reply);
            }
            $client_socket->close;
        }
    }
}

__PACKAGE__->meta->make_immutable;
1;
