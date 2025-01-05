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
        'asus.hostmaster.org' => {
            check_battery => [],
            check_power => [],
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

sub check_battery {
    my ($self, $server) = @_;
    my $result;

    my $energy_full = read_file('/sys/class/power_supply/BAT0/energy_full', err_mode => 'quiet');
    chomp $energy_full;
    my $energy_now = read_file('/sys/class/power_supply/BAT0/energy_now', err_mode => 'quiet');
    chomp $energy_now;
    my $status = $energy_now / $energy_full;
    if ($status > 0.75) {
        $result = sprintf("OK: %i%%\n", $status * 100);
    } elsif ($status > 0.25) {
        $result = sprintf("WARNING: %i%%", $status * 100);
    } else {
        $result = sprintf("ERROR: %i%%", $status * 100);
    }
    return $result;
}

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
    my $res = $ua->get("http://$server/");
    if ($res->is_success) {
        $result = "OK: ".$res->status_line;
    } else {
        $result = "ERROR: ".$res->status_line;
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
        $result = sprintf("OK: %s %.3f %i %s\n",
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

sub check_power {
    my ($self, $server) = @_;
    my $result;

    my $status = read_file('/sys/class/power_supply/AC0/online', err_mode => 'quiet');
    chomp $status;
    if ($status eq '1') {
        $result = "OK: Online";
    } else {
        $result = "ERROR: Offline";
    }
    return $result;
}

sub check_smtp {
    my ($self, $server) = @_;
    my $result;

    my $sock = IO::Socket::IP->new(
        Blocking => 0,
        PeerAddr => $server,
        PeerPort => 25,
        Proto    => 'tcp',
        Timeout  => 6,
    );
    if ($sock) {
        my $banner;
        my $timeout = Time::HiRes::time + 6;
        while (Time::HiRes::time < $timeout) {
            my $buf;
            $sock->read($buf, 1024);
            $banner .= $buf if length($buf);
            Time::HiRes::sleep(0.1);
        }
        chomp $banner;
        $result = "OK: $banner";
        $sock->close;
    } else {
        $result = "ERROR: $!";
    }
    return $result;
}

sub check_ssh {
    my ($self, $server) = @_;
    my $result;

    my $sock = IO::Socket::IP->new(
        Blocking => 0,
        PeerAddr => $server,
        PeerPort => 22,
        Proto    => 'tcp',
        Timeout  => 6,
    );
    if ($sock) {
        $sock->blocking(0);
        my $banner;
        my $timeout = Time::HiRes::time + 6;
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
    my $result = '';

    my $sock = IO::Socket::IP->new(
        PeerAddr => $server,
        PeerPort => 11,
        Proto    => 'tcp',
    );
    if ($sock) {
        $sock->blocking(0);
        my $timeout = Time::HiRes::time + 6;
        while (Time::HiRes::time < $timeout) {
            my $buf;
            $sock->sysread($buf, 1024);
            $result .= $buf if length($buf);
            Time::HiRes::sleep 0.1;
        }
        $sock->close;
        if ($result =~ /^(\d+\.\d+)\s+(\d+\.\d+)\s+(\d+\.\d+)/) {
            if ($1 > 8 || $2 > 4 || $3 > 2) {
                $result = "ERROR: $result";
            } elsif ($1 > 4 || $2 > 2 || $3 > 1) {
                $result = "WARNING: $result";
            } else {
                $result = "OK: $result";
            }
        } else {
            $result = "ERROR: $result";
        }
    } else {
        $result = "ERROR: $!";
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
            Ninkilim->log->debug("$server $check");
            my @args = @{$self->CHECKS()->{$server}->{$check}};
            $result->{$server}->{$check}->{result} = $self->$check($server, @args);
            $result->{$server}->{$check}->{date} = POSIX::strftime("%Y-%m-%dT%H:%M:%S", gmtime(time));
            Ninkilim->log->debug($result->{$server}->{$check}->{date}.' '.$result->{$server}->{$check}->{result});
        }
    }
    $self->write_results($result);
}

sub write_results {
    my ($self, $results) = @_;

    $results = JSON::encode_json($results);
    File::Slurp::write_file(Ninkilim->path_to(qw/root checkit.json/), $results);
}

__PACKAGE__->meta->make_immutable;

1;
