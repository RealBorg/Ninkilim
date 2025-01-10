package Ninkilim::Model::DNS;
use Moose;
use namespace::autoclean;

extends 'Catalyst::Model';

use File::Slurp;
use Net::DNS;
use POSIX;

use strict;
use warnings;

my $mtime = 0;
my $records;

sub load_records {
    my ($self, $file) = @_;

    my $stat = [ stat($file) ];
    unless ($mtime == $stat->[9]) {
        my $data = File::Slurp::read_file($file, array_ref => 1, chomp => 1, err_mode => 'croak');
        my $new_records;
        for my $line (@{$data}) {
            next if $line =~ /^$/;
            next if $line =~ /^#/;
            my ($name, $class, $type, $value) = split(/\s+/, $line, 4);
            $value = '' unless defined($value);
            push @{$new_records->{$name}->{$class}->{$type}}, $value;
        }
        $records = $new_records;
        $mtime = $stat->[9];
    }
    return $records;
}

sub reply {
    my ($self, $file, $query) = @_;

    return undef unless $query;

    $self->load_records($file);

    unless (ref($query) eq 'Net::DNS::Packet') {
        $query = Net::DNS::Packet->new(\$query);
    }
    return undef unless $query && 
        $query->header->opcode eq 'QUERY' && 
        $query->header->qr == 0 && 
        $query->header->qdcount > 0;

    my $reply;
    for my $question ($query->question) {
        STDOUT->printf(
            "%s %s\n",
            __PACKAGE__, 
            $question->string,
        );
        if ($records->{lc($question->qname)}) {
            unless ($reply) {
                $reply = $query->reply($query);
                $reply->header->rcode('NOERROR');
                $reply->header->aa(1);
            }
            my @answer = $self->get_records($question->qname, $question->qclass, $question->qtype);
            my @additional;
            if ($question->qtype eq 'A') {
                @additional = $self->get_records($question->qname, 'IN', 'AAAA');
            } elsif ($question->qtype eq 'AAAA') {
                @additional = $self->get_records($question->qname, 'IN', 'A');
            } elsif ($question->qtype eq 'MX') {
                for (@answer) {
                    push @additional, $self->get_records($_->exchange, 'IN', 'A');
                    push @additional, $self->get_records($_->exchange, 'IN', 'AAAA');
                }
            } elsif ($question->qtype eq 'NS') {
                for (@answer) {
                    push @additional, $self->get_records($_->nsdname, 'IN', 'A');
                    push @additional, $self->get_records($_->nsdname, 'IN', 'AAAA');
                }
            }
            for (@answer, @additional) {
                STDOUT->printf(
                    "%s %s\n",
                    __PACKAGE__, 
                    $_->string,
                );
            }
            $reply->push(answer => @answer);
            $reply->push(additional => @additional);
        }
    }
    return $reply;
}

sub get_records {
    my ($self, $qname, $qclass, $qtype) = @_;

    my @result;

    if ($qtype eq 'AXFR') {
        for my $key (keys(%{$records})) {
            if ($key =~ /$qname$/i) {
                push @result, $self->get_records($key, $qclass, 'ANY');
            }
        }
    } elsif ($qtype eq 'ANY') {
        for my $type (keys(%{$records->{lc($qname)}->{$qclass}})) {
            push @result, $self->get_records($qname, $qclass, $type);
        }
    } else {
        for my $data (List::Util::shuffle(@{$records->{lc($qname)}->{$qclass}->{$qtype}})) {
            my $rr = Net::DNS::RR->new("$qname $qclass $qtype $data");
            if ($qtype eq 'MX') {
                $rr->preference(10) unless $rr->preference;
                $rr->exchange($rr->owner) unless $rr->exchange;
            } elsif ($qtype eq 'NS') {
                $rr->nsdname($rr->owner) unless $rr->nsdname;
            } elsif ($qtype eq 'SOA') {
                $rr->mname($rr->owner) unless $rr->mname;
                $rr->rname('hostmaster.'.$rr->owner) unless $rr->rname;
                $rr->serial($mtime) unless $rr->serial;
                $rr->refresh(24*60*60) unless $rr->refresh;
                $rr->retry(60*60) unless $rr->retry;
                $rr->expire(365*24*60*60) unless $rr->expire;
                $rr->minimum(60*60) unless $rr->minimum;
            }
            $rr->ttl(60*60) unless $rr->ttl;
            push @result, $rr;
        }
    }
    return @result;
}

__PACKAGE__->meta->make_immutable;

1;
