package Ninkilim::Controller::Sync::Run;
use Moose;
use namespace::autoclean;
use File::Slurp;
use LWP::UserAgent;
use JSON;

BEGIN { extends 'Catalyst::Controller'; }

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    my $model = $c->model('DB');
    my $rs_peers = $model->resultset('Peer');
    my $rs_user = $model->resultset('User');
    my $ua = LWP::UserAgent->new;
    my $json = JSON->new;
    for my $peer (read_file($c->path_to('root', 'peers.txt'), { chomp => 1, err_mode => 'quiet' })) {
        $rs_peers->find_or_create(
            {
                url => $peer,
            }
        );
    }
    for my $peer ($rs_peers->all) {
        my $model = $c->model('DB');
        my $uri = URI->new($peer->url);
        $uri->query_form(
            format => 'json',
            include_replies => 1,
            include_rt => 1,
            min_id => $peer->last_id,
            rows => 100,
            sort => 'asc',
        );
        my $data = $ua->get($uri);
        $c->log->debug("Fetching $uri: ".$data->status_line);
        if ($data->is_success) {
            $data = $data->decoded_content;
            $data = $json->decode($data);
            for my $posting (@{$data->{postings}}) {
                $peer->update({ last_id => $posting->{id} });
                $c->log->debug("Found posting ".$posting->{id});
                $model->txn_do(sub {

                    my $user = $rs_user->find_or_create(
                        {
                            id => $posting->{author}->{id},
                            email => $posting->{author}->{email},
                            username => $posting->{author}->{username},
                            displayname => $posting->{author}->{displayname},
                            bio => $posting->{author}->{bio},
                            website => $posting->{author}->{website},
                            location => $posting->{author}->{location},
                        }
                    );
                    my $posting_db = $user->find_or_create_related('postings',
                        {
                            id => $posting->{id},
                            date => $posting->{date},
                            text => $posting->{text},
                            lang => $posting->{lang},
                            parent => $posting->{parent} ? $posting->{parent} : undef,
                        }
                    );
                    for my $media (@{$posting->{medias}}) {
                        my $posting_id = $posting->{id};
                        if ($media->{filename} =~ /^$posting_id-/) {
                            $c->log->debug("Found media ".$media->{filename});

                            $posting_db->find_or_create_related('medias',
                                {
                                    filename => $media->{filename},
                                    type => $media->{type},
                                }
                            );

                            my $filename = ''.$c->path_to('root', 'static', 'media', $media->{filename});
                            if (-f $filename) {
                                my $response = $ua->head($media->{url});
                                if ($response->header('Content-Length') && $response->header('Content-Length') != -s $filename) {
                                    unlink $filename;
                                }
                            }
                            unless (-f $filename) {
                                my $response = $ua->get($media->{url}, ':content_file' => "$filename");
                                unless ($response->is_success) {
                                    unlink $filename;
                                }
                            }
                        }
                    }
                });
            }
        }
    }
}

__PACKAGE__->meta->make_immutable;

1;
