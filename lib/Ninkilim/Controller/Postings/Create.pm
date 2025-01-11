package Ninkilim::Controller::Postings::Create;
use Moose;
use namespace::autoclean;
use DateTime;
use Time::HiRes;
use Data::Dumper;

use constant {
    CHARSET => [ '0'..'9', 'a'..'z', 'A'..'Z' ],
    TWITTER_EPOCH => 1288834974657, # milliseconds since 2010-11-04T01:42:54
};

BEGIN { extends 'Catalyst::Controller'; }

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    my $user = $c->user;
    $c->detach('/forbidden') unless $user;

    my $draft_id = int($c->req->param('id')) || int(rand(2**22));
    $draft_id &= 2**22-1;

    my $posting = $c->session->{'drafts'}->{$draft_id};
    $posting->{'id'} = $draft_id;
    $posting->{'lang'} = $c->req->param('lang') || 'en';
    $posting->{'date'} = DateTime->now()->iso8601();
    $posting->{'text'} = $c->req->param('text') || '';
    $posting->{'parent'} = undef;

    if ($c->req->method eq 'POST') {
        if ($c->req->param('post')) {
            my $id = Time::HiRes::time * 1000 - TWITTER_EPOCH();
            $id = $id << 22;
            $id += $draft_id;
            $posting->{'id'} = $id;

            for my $media (@{$posting->{medias}}) {
                my $filename = sprintf("%s-%s", $posting->{id}, $media->{'filename'});
                rename $c->path_to('root', 'static', 'media', $media->{'filename'}), 
                    $c->path_to('root', 'static', 'media', $filename);
                symlink "../media/$filename", $c->path_to('root', 'static', 'tweets_media', $filename);
                $media->{'filename'} = $filename;
            }

            $posting = $user->create_related('postings', $posting);

            delete $c->session->{'drafts'}->{$id};
            $c->response->redirect($c->uri_for('/postings', $posting->id));
            $c->detach;
        } elsif (my $file = $c->req->upload('file')) {
            my $path = $c->path_to('root', 'static', 'media');
            mkdir $path;
            my $filename;
            for (my $i = 0; $i < 15; $i++) {
                $filename .= CHARSET->[int(rand(scalar(@{CHARSET()})))];
            }
            if ($file->type eq 'image/jpeg') {
                $filename .= '.jpg';
                $file->copy_to("$path/$filename");
                push @{$posting->{'medias'}}, {
                    filename => $filename,
                    type => 'image',
                };
            } elsif ($file->type eq 'image/png') {
                $filename .= '.png';
                $file->copy_to("$path/$filename");
                push @{$posting->{'medias'}}, {
                    filename => $filename,
                    type => 'image',
                };
            } elsif ($file->type eq 'video/mp4') {
                $filename .= '.mp4';
                $file->copy_to("$path/$filename");
                push @{$posting->{'medias'}}, {
                    filename => $filename,
                    type => 'video',
                };
            } else {
                # ignore
            }
        }
    }
    $c->stash->{'posting'} = $posting;
    $c->session->{'drafts'}->{$draft_id} = $posting;
}

__PACKAGE__->meta->make_immutable;

1;
