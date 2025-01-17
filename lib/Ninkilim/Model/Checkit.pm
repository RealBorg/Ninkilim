package Ninkilim::Model::Checkit;
use Moose;
use namespace::autoclean;

extends 'Catalyst::Model';

use DateTime;
use File::Slurp;
use IO::Socket::IP;
use IO::Socket::SSL;
use IO::Socket::SSL::Utils;
use JSON;
use LWP::UserAgent;
use Net::DNS;
use Net::NTP;
use Socket;
use Time::HiRes;

use constant {
    CHECKS => {
        'amsterdam.hostmaster.org' => {
            check_dns => [ 'hostmaster.org' ],
            check_http => [],
            check_https => [],
            check_ntp => [],
            check_smtp => [],
            check_ssh => [],
            check_systat => [],
        },
        'fremont.hostmaster.org' => {
            check_dns => [ 'hostmaster.org' ],
            check_http => [],
            check_https => [],
            check_ntp => [],
            check_smtp => [],
            check_ssh => [],
            check_systat => [],
        },
        'jakarta.hostmaster.org' => {
            check_dns => [ 'hostmaster.org' ],
            check_http => [],
            check_https => [],
            check_ntp => [],
            check_smtp => [],
            check_ssh => [],
            check_systat => [],
        },
        'madrid.hostmaster.org' => {
            check_dns => [ 'hostmaster.org' ],
            check_http => [],
            check_https => [],
            check_ntp => [],
            check_smtp => [],
            check_ssh => [],
            check_systat => [],
        },
        'stockholm.hostmaster.org' => {
            check_dns => [ 'hostmaster.org' ],
            check_http => [],
            check_https => [],
            check_ntp => [],
            check_smtp => [],
            check_ssh => [],
            check_systat => [],
        },
    },
};

sub check_dns {
    my ($self, $server, $name) = @_;

    my $result;

    my $resolver = Net::DNS::Resolver->new;
    $resolver->nameservers($server);
    my $response = $resolver->query($name, "A");
    if ($response) {
        $response = [ $response->answer ];
        $response = [ map($_->address, @{$response}) ];
        $response = [ sort( { inet_aton($a) cmp inet_aton($b) } @{$response}) ];
        $result = "OK: " . join(", ", @{$response});
    } else {
        $result = "ERROR: ", $resolver->errorstring;
    }
    return $result;
}

sub check_http {
    my ($self, $server) = @_;
    my $result;

    my $ua = LWP::UserAgent->new(timeout => 6);
    my $time = Time::HiRes::time;
    my $res = $ua->get("http://$server/");
    if ($res->is_success) {
        $result = sprintf("OK: %s, %.3fs", $res->status_line, Time::HiRes::time - $time);
    } else {
        $result = sprintf("ERROR: %s, %.3fs", $res->status_line, Time::HiRes::time - $time);
    }
    return $result;
}

sub check_https {
    my ($self, $server) = @_;
    my $result;

    my $sock = IO::Socket::SSL->new(
        PeerHost => $server,
        PeerPort => 443,
    );
    if ($sock) {
        my $cert = $sock->peer_certificate;
        $cert = CERT_asHash($cert);
        my $not_after = $cert->{not_after};
        $result = DateTime->from_epoch(epoch => $not_after)->iso8601;
        if ($not_after < time) {
            $result = "ERROR: $result";
        } elsif (($not_after + 7 * 24 * 60 * 60) < time) {
            $result = "WARNING: $result";
        } else {
            $result = "OK: $result";
        }
        $sock->close;
    } else {
        $result = "ERROR: $!";
    }
    return $result;
}

sub check_ntp {
    my ($self, $server) = @_;
    my $result;

    my $response;
    eval {
        $response = { Net::NTP::get_ntp_response($server) };
    };
    if ($response) {
        $result = sprintf("OK: %s %.3f %i %s",
            DateTime->from_epoch(epoch => $response->{'Destination Timestamp'})->iso8601,
            $response->{Offset},
            $response->{Stratum},
            $response->{'Reference Clock Identifier'},
        );
    } else {
        $result = "ERROR: $@";
    }
    return $result;
}

sub check_smtp {
    my ($self, $server) = @_;
    my $result = '';

    my $sock = IO::Socket::IP->new(
        PeerAddr => $server,
        PeerPort => 25,
        Proto    => 'tcp',
        Timeout  => 6,
    );
    if ($sock) {
        my $timeout = Time::HiRes::time + 6;
        $sock->blocking(0);
        while (Time::HiRes::time < $timeout) {
            my $buf;
            $sock->read($buf, 1024);
            $result .= $buf if length($buf);
            Time::HiRes::sleep(0.1);
        }
        $sock->close;
        chomp $result;
        if ($result =~ /^220\s+/) {
            $result = "OK: $result";
        } else {
            $result = "ERROR: $result";
        }
    } else {
        $result = "ERROR: $!";
    }
    return $result;
}

sub check_ssh {
    my ($self, $server) = @_;
    my $result;

    my $sock = IO::Socket::IP->new(
        PeerAddr => $server,
        PeerPort => 22,
        Proto    => 'tcp',
        Timeout  => 6,
    );
    if ($sock) {
        my $banner;
        my $timeout = Time::HiRes::time + 6;
        $sock->blocking(0);
        while (Time::HiRes::time < $timeout) {
            my $buf;
            $sock->read($buf, 1024);
            $banner .= $buf if length($buf);
            Time::HiRes::sleep 0.1;
        }
        chomp $banner;
        $result = "OK: $banner";
        $sock->close;
    } else {
        $result = "ERROR: $!";
    }
    return $result;
}

sub check_systat {
    my ($self, $server) = @_;
    my $result;
    my $error = 0;
    my $warning = 0;

    my $ua = LWP::UserAgent->new;
    $ua->timeout(6);
    my $res = $ua->get("http://$server/status?format=json");
    if ($res->is_success) {
        $res = $res->decoded_content;
        $res = JSON::decode_json($res);
        $res = $res->{'status'};
        if ($res->{memory}) {
            push @{$result}, sprintf("m: %.2f", $res->{memory});
            if ($res->{memory} > 31/32) {
                $error = 1;
            } elsif ($res->{memory} > 15/16) {
                $warning = 1;
            }
        }
        if ($res->{swap}) {
            push @{$result}, sprintf("s: %.2f", $res->{swap});
        }
        if ($res->{ac}) {
            if ($res->{ac} == 1) {
                push @{$result}, 'AC';
            } else {
                push @{$result}, 'BA';
                $warning = 1;
            }
        }
        if ($res->{battery}) {
            push @{$result}, sprintf("b: %.2f", $res->{battery});
            if ($res->{battery} < 3/4) {
                $warning = 1;
            } elsif ($res->{battery} < 1/4) {
                $error = 1;
            }
        }
        if (defined($res->{load1}) && defined($res->{load5}) && defined($res->{load15})) {
            push @{$result}, sprintf("l: %s %s %s", $res->{load1}, $res->{load5}, $res->{load15});
            if ($res->{load1} > 4 || $res->{load5} > 2 || $res->{load15} > 1) {
                $error = 1;
            } elsif ($res->{load1} > 2 || $res->{load5} > 1 || $res->{load15} > 0.5) {
                $warning = 1;
            }
        }
        if ($res->{uptime}) {
            push @{$result}, sprintf("u: %s", $res->{uptime});
        }
        $result = join(' ', @{$result});
        if ($error) {
            $result = "ERROR: $result";
        } elsif ($warning) {
            $result = "WARNING: $result";
        } else {
            $result = "OK: $result";
        }
    } else {
        $result = sprintf("ERROR: %s", $res->status_line);
    }
    return $result;
}

sub get_results {
    my ($self) = @_;

    my $results = File::Slurp::read_file(Ninkilim->path_to(qw/root checkit.json/), err_mode => 'quiet');
    $results = JSON::decode_json($results);

    return $results;
}

sub run_checks {
    my ($self) = @_;

    my $result;
    for my $server (sort(keys(%{$self->CHECKS}))) {
        for my $check (sort(keys(%{$self->CHECKS()->{$server}}))) {
            STDOUT->printf(
                "%s %s\n",
                $server,
                $check,
            );
            my @args = @{$self->CHECKS()->{$server}->{$check}};
            eval {
                $result->{$server}->{$check}->{result} = $self->$check($server, @args);
            };
            if ($@) {
                $result->{$server}->{$check}->{result} = "ERROT: $@";
            }
            $result->{$server}->{$check}->{date} = POSIX::strftime("%Y-%m-%dT%H:%M:%S", gmtime(time));
            STDOUT->printf(
                "%s %s\n",
                $result->{$server}->{$check}->{date},
                $result->{$server}->{$check}->{result},
            );
        }
    }
    return $result;
}

__PACKAGE__->meta->make_immutable;

1;
