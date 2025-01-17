package Ninkilim::Controller::Root::Static;
use Moose;
use namespace::autoclean;
use File::Slurp;
use HTTP::Date;
use MIME::Types;
use Cwd;
use POSIX;
use Data::Dumper;

BEGIN { extends 'Catalyst::Controller' }

my $mime_types = MIME::Types->new(only_complete => 1);
my $static;

sub find_files {
    my ( $self, $dir ) = @_;

    my $dir_stat = [ stat($dir) ];
    if ($static->{dirs}->{$dir}->{mtime} && $static->{dirs}->{$dir}->{mtime} == $dir_stat->[9]) {
        for my $path (keys(%{$static->{dirs}->{$dir}->{dirs}})) {
            $self->find_files($path);
        }
    } else {
        delete $static->{dirs}->{$dir}->{files};
        delete $static->{dirs}->{$dir}->{dirs};
        for my $path (File::Slurp::read_dir($dir, err_mode => 'quiet', prefix => 1)) {
            my $stat = [ stat($path) ];
            if (-f $path) {
                $static->{dirs}->{$dir}->{files}->{$path}->{mtime} = $stat->[9];
                $static->{dirs}->{$dir}->{files}->{$path}->{size} = $stat->[7];
            } elsif (-d $path) {
                $self->find_files($path);
                $static->{dirs}->{$dir}->{dirs}->{$path}->{mtime} = $stat->[9];
            }
        }
        $static->{dirs}->{$dir}->{mtime} = $dir_stat->[9];
    }
    delete $static->{files};
    for my $dir (keys(%{$static->{dirs}})) {
        for my $file (keys(%{$static->{dirs}->{$dir}->{files}})) {
            $static->{files}->{$file} = $static->{dirs}->{$dir}->{files}->{$file};
        }
    }
    return $static->{files};
}

sub index :Path :Args {
    my ( $self, $c, @args ) = @_;

    my $files = $self->find_files($c->path_to('root', 'static'));
    my $host = $c->req->header('Host');
    $host =~ s/:\d+$//;
    $c->res->status(404);
    for my $path ($c->path_to('root', 'static', $host, $c->req->path), $c->path_to('root', 'static', $c->req->path)) {
        if (my $file = $files->{$path}) {
            $c->res->status(200);
            my $ifmodified = $c->req->header('If-Modified');
            $ifmodified = HTTP::Date::str2time($ifmodified) if $ifmodified;
            if ($ifmodified && $ifmodified == $file->{mtime}) {
                $c->detach('/notmodified');
            } else {
                if (my $mime_type = $mime_types->mimeTypeOf($path)) {
                    $c->res->header('Content-Type' => $mime_type->type);
                }
                $c->res->header('Content-Length' => $file->{size});
                $c->res->header('Last-Modified' => HTTP::Date::time2str($file->{mtime}));
                if ($c->req->method eq 'HEAD') {
                    $c->stash->{'format'} = 'none';
                } elsif ($c->req->method eq 'GET') {
                    $c->stash->{'format'} = 'none';
                    my $fh = IO::File->new($path, 'r');
                    binmode $fh;
                    $c->res->body($fh);
                } else {
                    $c->detach('/methodnotfound');
                }
            }
            last;
        }
    }
    if ($c->res->status == 404) {
        $c->detach('/notfound');
    }
}

__PACKAGE__->meta->make_immutable;

1;
