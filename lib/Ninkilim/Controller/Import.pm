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
                uri => '',
                name => $account->{accountDisplayName},
                description => $profile->{description}->{bio},
            }
        );
        my $note_tweets = read_file($c->path_to(qw/root note-tweet.js/));
        $note_tweets =~ s/window.YTD.note_tweet.part0 = //;
        $note_tweets = $json->decode($note_tweets);
        my $strp = DateTime::Format::Strptime->new(pattern => '%Y-%m-%dT%H:%M:%S.%3NZ');
        my $note_tweets_by_date;
        for my $note_tweet (@{$note_tweets}) {
            $note_tweet = $note_tweet->{noteTweet};
            my $date = $strp->parse_datetime($note_tweet->{createdAt})->iso8601;
            $note_tweets_by_date->{$date} = $note_tweet->{core}->{text};
        }
        $strp = DateTime::Format::Strptime->new(pattern => '%a %b %d %H:%M:%S %z %Y');
        for my $file (qw/tweets.js tweets-part1.js/) {
            my $tweets = read_file($c->path_to("root", $file));
            $tweets =~ s/^window.YTD.tweets.part\d+ = //;
            $tweets = $json->decode($tweets);
            for my $tweet (@{$tweets}) {
                $tweet = $tweet->{tweet};
                my $date = $strp->parse_datetime($tweet->{created_at})->iso8601;
                my $text = $tweet->{full_text};
                if (exists($note_tweets_by_date->{$date})) {
                    $text = $note_tweets_by_date->{$date};
                }
                my $posting = $source->create_related('postings',
                    {
                        id => $tweet->{id},
                        created_at => $date,
                        full_text => $text,
                        lang => $tweet->{lang},
                        in_reply_to => $tweet->{in_reply_to_status_id},
                    }
                );
                for my $image (glob($c->path_to('root', 'static', 'tweets_media', $tweet->{id}."-*.jpg")), glob($c->path_to('root', 'static', 'tweets_media', $tweet->{id}.'-*.png'))) {
                    $image =~ s/^.*\///;
                    $posting->create_related('medias',
                        {
                            filename => $image,
                            media_type => 'image',
                        }
                    );
                }
                for my $video (glob($c->path_to('root', 'static', 'tweets_media', $tweet->{id}.'-*.mp4'))) {
                    $video =~ s/^.*\///;
                    $posting->create_related('medias',
                        {
                            filename => $video,
                            media_type => 'video',
                        }
                    );
                }
            }
        }
    });
    $c->response->body('Matched Ninkilim::Controller::Import in Import.');
}

__PACKAGE__->meta->make_immutable;

1;
