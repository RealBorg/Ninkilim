package Ninkilim::Controller::Articles;
use Moose;
use namespace::autoclean;
use Encode;
use File::Slurp;
use Text::MultiMarkdown;

BEGIN { extends 'Catalyst::Controller'; }

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    unless ($c->stash->{articles}) {
        my $dir = $c->path_to('root', 'articles');
        for (sort(glob("$dir/*/*"))) {
            if (/$dir\/(.*)\/(.*)\.md/) {
                warn "$1 $2";
                my $title = $1;
                my $lang = $2;
                $c->stash->{articles}->{$title}->{$lang} = 1;
                $c->stash->{article_titles}->{$title} = $self->title($title);
            }
        }
    }
}

sub article :Path :Args(1) {
    my ( $self, $c, $title ) = @_;

    $self->index($c);
    my $langs;
    for my $lang (split(/,/, ($c->request->headers->header('Accept-Language') || ''))) {
        $lang =~ s/^([a-z]{2})/$1/;
        next unless $lang;
        push @{$langs}, $lang;
    }
    push @{$langs}, 'en';

    $c->res->status(404);
    foreach my $lang (@{$langs}) {
        if ($c->stash->{articles}->{$title}->{$lang}) {
            $c->res->status(200);
            $self->article_lang($c, $title, $lang);
            last;
        }
    }
}

sub article_lang :Path :Args(2) {
    my ($self, $c, $title, $lang) = @_;

    $self->index($c);
    if ($c->stash->{articles}->{$title}->{$lang}) {
        $c->stash->{'lang'} = $lang;
        my $markdown = $c->path_to('root', 'articles', $title, "$lang.md");
        $markdown = read_file($markdown);
        $markdown = decode('UTF-8', $markdown);
        $markdown = Text::MultiMarkdown::markdown($markdown);
        $c->stash->{'article'} = $markdown;
        $c->stash->{'title'} = $self->title($title);
        $c->stash->{template} = 'articles/article_lang.tt2';
    } else {
        $c->res->status(404);
    }
}

sub sitemap :Local :Args(0) {
    my ( $self, $c ) = @_;

    $self->index($c);
    my $urls;
    for my $title (sort(keys(%{$c->stash->{articles}}))) {
        for my $lang (sort(keys(%{$c->stash->{articles}->{$title}}))) {
            push @{$urls}, { loc => [ $c->uri_for('/articles', $title, $lang)->as_string ] };
        }
    }
    $c->stash->{'data'}->{'urlset'} = {
        url => $urls,
        xmlns => 'http://www.sitemaps.org/schemas/sitemap/0.9',
    };
    $c->stash->{'xmlopts'} = {
        RootName => undef,
        XMLDecl => '<?xml version="1.0" encoding="UTF-8"?>', 
        NoAttr => 0, 
        AttrIndent => 1,
        #KeepRoot => 1,
    };
    $c->stash->{'format'} = 'xml';
}

sub title {
    my ($self, $title) = @_;

    $title =~ s/_/ /g;
    $title = join(' ', map(ucfirst($_), split(' ', $title)));

    return $title;
}

__PACKAGE__->meta->make_immutable;

1;
