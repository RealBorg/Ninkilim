package Ninkilim::Controller::Articles;
use Moose;
use namespace::autoclean;
use Encode;
use File::Slurp;
use Text::MultiMarkdown;

BEGIN { extends 'Catalyst::Controller'; }

sub begin :Private {
    my ( $self, $c, $title ) = @_;
}

sub index :Path :Args(1) {
    my ( $self, $c, $title ) = @_;

    $title =~ s/[^a-zA-Z0-9_-]//g;
    my $langs;
    for my $lang ($c->req->param('lang'), split(/,/, ($c->request->headers->header('Accept-Language') || ''))) {
        next unless $lang;
        $lang =~ s/;.*//;
        $lang =~ s/[^a-z]//g;
        push @{$langs}, $lang;
    }
    push @{$langs}, 'en';

    $c->res->status(404);
    foreach my $lang (@{$langs}) {
        my $path = $c->path_to("root", "articles", $title, "$lang.md");
        if (-f $path) {
            $c->res->status(200);
            $c->stash->{'lang'} = $lang;
            my $markdown = read_file($path);
            $markdown = decode('UTF-8', $markdown);
            $c->stash->{'article'} = Text::MultiMarkdown::markdown($markdown);
            $path =~ s/.*\/(.*)\/.*/$1/;
            $path =~ s/_/ /g;
            $path = join(' ', map(ucfirst($_), split(' ', $path)));
            $c->stash->{'title'} = $path;
            last;
        }
    }
}

sub end :Private {
    my ( $self, $c, $title ) = @_;

    $c->forward('View::HTML');
}

__PACKAGE__->meta->make_immutable;

1;
