package Ninkilim::Controller::Import;
use DateTime::Format::Strptime;
use Moose;
use namespace::autoclean;
use File::Slurp;
use JSON;

BEGIN { extends 'Catalyst::Controller'; }

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;
    

    return $c->detach('/forbidden') unless $c->req->address eq '127.0.0.1';
    my $model = $c->model('DB');
    $model->schema->txn_do(sub {
        my $json = JSON->new;
        $json->utf8(1);

        my $account = read_file($c->path_to(qw/root account.js/));
        $account =~ s/window.YTD.account.part0 = //;
        $account = $json->decode($account);
        $account = $account->[0]->{account};

        my $profile = read_file($c->path_to(qw/root profile.js/));
        $profile =~ s/window.YTD.profile.part0 = //;
        $profile = $json->decode($profile);
        $profile = $profile->[0]->{profile};
        my $source = $model->resultset('Source')->create(
            {
                name => $account->{accountDisplayName},
                description => $profile->{description}->{bio},
            }
        );
        my $strp = DateTime::Format::Strptime->new(pattern => '%a %b %d %H:%M:%S %z %Y');
        for my $file ($c->path_to('root', 'tweets.js'), glob($c->path_to('root', 'tweets-part*.js'))) {
            my $tweets = read_file($file);
            $tweets =~ s/^window.YTD.tweets.part\d+ = //;
            $tweets = $json->decode($tweets);
            for my $tweet (@{$tweets}) {
                $tweet = $tweet->{tweet};
                my $date = $strp->parse_datetime($tweet->{created_at})->iso8601;
                my $text = $tweet->{full_text};
                for my $entity (@{$tweet->{entities}->{urls}}) {
                    my $url = $entity->{url};
                    my $eurl = $entity->{expanded_url};
                    $text =~ s/$url/$eurl/;
                }
                for my $entity (@{$tweet->{extended_entities}->{media}}) {
                    my $url = $entity->{url};
                    $text =~ s/$url//;
                }
                my $posting = $source->create_related('postings',
                    {
                        id => $tweet->{id},
                        date => $date,
                        text => $text,
                        lang => $tweet->{lang},
                        parent => $tweet->{in_reply_to_status_id},
                    }
                );
                for my $image (glob($c->path_to('root', 'static', 'tweets_media', $tweet->{id}."-*.jpg")), glob($c->path_to('root', 'static', 'tweets_media', $tweet->{id}.'-*.png'))) {
                    $image =~ s/^.*\///;
                    $posting->create_related('medias',
                        {
                            filename => $image,
                            type => 'image',
                        }
                    );
                }
                for my $video (glob($c->path_to('root', 'static', 'tweets_media', $tweet->{id}.'-*.mp4'))) {
                    $video =~ s/^.*\///;
                    $posting->create_related('medias',
                        {
                            filename => $video,
                            type => 'video',
                        }
                    );
                }
            }
        }
        if (my $note_tweets = read_file($c->path_to('root', 'note-tweet.js'))) {
            $note_tweets =~ s/window.YTD.note_tweet.part0 = //;
            $note_tweets = $json->decode($note_tweets);
            my $strp = DateTime::Format::Strptime->new(pattern => '%Y-%m-%dT%H:%M:%S.%3NZ');
            for my $note_tweet (@{$note_tweets}) {
                $note_tweet = $note_tweet->{noteTweet};
                my $date = $strp->parse_datetime($note_tweet->{createdAt})->iso8601;
                $source->search_related('postings', { date => $date })->update({ text => $note_tweet->{core}->{text} });
            }
        }
    });
    $c->response->body('Matched Ninkilim::Controller::Import in Import.');
}

__PACKAGE__->meta->make_immutable;

1;
