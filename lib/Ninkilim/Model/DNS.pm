package Ninkilim::Model::DNS;
use Moose;
use namespace::autoclean;

extends 'Catalyst::Model';

use Data::Dumper;
use Net::DNS;
use Ninkilim;
use POSIX;

use strict;
use warnings;

sub load_records {
    my ($self) = @_;

    my $file = Ninkilim->path_to(qw/root dns.txt/);
    my $stat = [ stat($file) ];
    unless (($self->{mtime} || 0) == $stat->[9]) {
        $file = File::Slurp::read_file($file, array_ref => 1, chomp => 1, err_mode => 'croak');
        for my $line (@{$file}) {
            next if $line =~ /^$/;
            next if $line =~ /^#/;
            my ($name, $class, $type, $data) = split(/\s+/, $line, 4);
            $data = '' unless defined($data);
            push @{$self->{records}->{$name}->{$class}->{$type}}, $data;
        }
        $self->{mtime} = $stat->[9];
    }
}

sub reply {
    my ($self, $from_addr, $query) = @_;

    return undef unless $query;

    $self->load_records;

    unless (ref($query) eq 'Net::DNS::Packet') {
        $query = Net::DNS::Packet->new(\$query);
    }
    return undef unless $query && 
        $query->header->opcode eq 'QUERY' && 
        $query->header->qr == 0 && 
        $query->header->qdcount > 0;

    my $reply;
    for my $question ($query->question) {
        Ninkilim->log->debug(
            sprintf(
                "%s %s %s %s\n", 
                __PACKAGE__, 
                POSIX::strftime('%Y-%m-%dT%H:%M:%S', gmtime(time)),
                $from_addr,
                $question->string,
            )
        );
        if ($self->{records}->{lc($question->qname)}) {
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
                Ninkilim->log->debug(
                    sprintf(
                        "%s %s %s %s\n", 
                        __PACKAGE__, 
                        POSIX::strftime('%Y-%m-%dT%H:%M:%S', gmtime(time)),
                        $from_addr,
                        $_->string,
                    )
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
        for my $key (keys(%{$self->{records}})) {
            if ($key =~ /$qname$/i) {
                push @result, $self->get_records($key, $qclass, 'ANY');
            }
        }
    } elsif ($qtype eq 'ANY') {
        for my $type (keys(%{$self->{records}->{lc($qname)}->{$qclass}})) {
            push @result, $self->get_records($qname, $qclass, $type);
        }
    } else {
        for my $data (List::Util::shuffle(@{$self->{records}->{lc($qname)}->{$qclass}->{$qtype}})) {
            my $rr = Net::DNS::RR->new("$qname $qclass $qtype $data");
            if ($qtype eq 'MX') {
                $rr->preference(10) unless $rr->preference;
                $rr->exchange($rr->owner) unless $rr->exchange;
            } elsif ($qtype eq 'NS') {
                $rr->nsdname($rr->owner) unless $rr->nsdname;
            } elsif ($qtype eq 'SOA') {
                $rr->mname($rr->owner) unless $rr->mname;
                $rr->rname('hostmaster.'.$rr->owner) unless $rr->rname;
                $rr->serial($self->{mtime}) unless $rr->serial;
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
