package Ninkilim::Controller::Import;
use DateTime::Format::Strptime;
use Digest::SHA;
use Moose;
use namespace::autoclean;
use File::Slurp;
use JSON;

BEGIN { extends 'Catalyst::Controller'; }

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    return $c->detach('/forbidden') unless $c->req->address eq '127.0.0.1';
    
    $c->log->enable(qw/debug info warn error fatal/);
    $c->log->autoflush(1);

    my $json = JSON->new;
    $json->utf8(1);

    my $model = $c->model('DB');
    $model->txn_do(
        sub {
            $c->log->debug("Processing account.js");
            my $account = read_file($c->path_to(qw/root account.js/));
            $account =~ s/window.YTD.account.part0 = //;
            $account = $json->decode($account);
            $account = $account->[0]->{account};

            $c->log->debug("Processing profile.js");
            my $profile = read_file($c->path_to(qw/root profile.js/));
            $profile =~ s/window.YTD.profile.part0 = //;
            $profile = $json->decode($profile);
            $profile = $profile->[0]->{profile};

            my $user = $model->resultset('User')->find(
                {
                    id => $account->{accountId},
                }
            );
            if ($user) {
                $c->log->debug('Found user '.$account->{accountId});
                my $email = Digest::SHA::sha512_base64($account->{email});
                $user->update(
                    {
                        email => $email,
                        username => $account->{username},
                        displayname => $account->{accountDisplayName},
                        bio => $profile->{description}->{bio},
                        website => $profile->{description}->{website},
                        location => $profile->{description}->{location},
                    }
                );
            } else {
                $c->log->debug('Created user '.$account->{accountId});
                my $email = Digest::SHA::sha512_base64($account->{email});
                $user = $model->resultset('User')->create(
                    {
                        id => $account->{accountId},
                        email => $email,
                        username => $account->{username},
                        displayname => $account->{accountDisplayName},
                        bio => $profile->{description}->{bio},
                        website => $profile->{description}->{website},
                        location => $profile->{description}->{location},
                    }
                );
            }

            my $strp = DateTime::Format::Strptime->new(pattern => '%a %b %d %H:%M:%S %z %Y');
            for my $file ($c->path_to('root', 'tweets.js'), glob($c->path_to('root', 'tweets-part*.js'))) {
                $c->log->debug("Processing $file");
                my $tweets = read_file($file);
                $tweets =~ s/^window.YTD.tweets.part\d+ = //;
                $tweets = $json->decode($tweets);
                for my $tweet_ (@{$tweets}) {
                    my $tweet = $tweet_->{tweet};
                    my $tweet_id = $tweet->{id};
                    my $posting = $user->find_related(
                        'postings',
                        {
                            id => $tweet_id,
                        }
                    );
                    if ($posting) {
                        $c->log->debug("Found posting $tweet_id");
                    } else {
                        $c->log->debug("Created posting $tweet_id");
                        my $date = $strp->parse_datetime($tweet->{created_at})->iso8601;
                        my $text = $tweet->{full_text};
                        for my $entity (@{$tweet->{entities}->{urls}}) {
                            my $url = $entity->{url};
                            my $expanded_url = $entity->{expanded_url};
                            $text =~ s/$url/$expanded_url/;
                        }
                        for my $entity (@{$tweet->{extended_entities}->{media}}) {
                            my $url = $entity->{url};
                            my $expanded_url = $entity->{expanded_url};
                            $text =~ s/$url/$expanded_url/;
                        }
                        my $posting = $user->create_related(
                            'postings',
                            {
                                id => $tweet_id,
                                date => $date,
                                text => $text,
                                lang => $tweet->{lang},
                                parent => $tweet->{in_reply_to_status_id},
                            }
                        );
                        for my $path (glob($c->path_to('root', 'static', 'media', "$tweet_id-*"))) {
                            my $file = $path;
                            $file =~ s/^.*\///;
                            if ($file =~ /\.(jpg|png)$/) {
                                $c->log->debug("Created image $file");
                                $posting->create_related('medias',
                                    {
                                        filename => $file,
                                        type => 'image',
                                    }
                                );
                            } elsif ($file =~ /\.mp4$/) {
                                $c->log->debug("Created video $file");
                                $posting->create_related('medias',
                                    {
                                        filename => $file,
                                        type => 'video',
                                    }
                                );
                            }
                        }
                    }
                }
            }
            if (my $note_tweets = read_file($c->path_to('root', 'note-tweet.js'))) {
                $c->log->debug("Processing note-tweets.js");
                $note_tweets =~ s/window.YTD.note_tweet.part0 = //;
                $note_tweets = $json->decode($note_tweets);
                for my $note_tweet_ (@{$note_tweets}) {
                    my $note_tweet = $note_tweet_->{noteTweet};
                    if (my $posting = $user->search_related('postings',
                            {},
                            { 
                                order_by => \[ 'ABS(id - ?)', $note_tweet->{noteTweetId} ],
                                rows => 1,
                            })->single) {
                        $c->log->debug("Updated posting ".$posting->id." with extended text");
                        my $text = $note_tweet->{core}->{text};
                        for my $url (@{$note_tweet->{core}->{urls}}) {
                            my $shortUrl = $url->{shortUrl};
                            my $expandedUrl = $url->{expandedUrl};
                            $text =~ s/$shortUrl/$expandedUrl/;
                        }
                        $posting->update({ text => $text });
                    }
                }
            }
        }
    );
    $c->res->content_type('text/plain');
    $c->response->body('IMPORT SUCCESSFULLY COMPLETED');
}

__PACKAGE__->meta->make_immutable;

1;
