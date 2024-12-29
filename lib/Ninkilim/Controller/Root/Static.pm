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
        for my $path (@{$static->{dirs}->{$dir}->{dirs}}) {
            $self->find_files($path);
        }
    } else {
        for my $path (File::Slurp::read_dir($dir, err_mode => 'quiet', prefix => 1)) {
            my $stat = [ stat($path) ];
            if (-f $path) {
                $static->{dirs}->{$dir}->{files}->{$path}->{mtime} = $stat->[9];
                $static->{dirs}->{$dir}->{files}->{$path}->{size} = $stat->[7];
            } elsif (-d $path) {
                $self->find_files($path);
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


    my $rootstatic = $c->path_to(qw/root static/);
    my $files = $self->find_files($c->path_to(qw/root static/));

    my $path = $rootstatic.'/'.$c->req->path();
    if (my $file = $files->{$path}) {
        my $fh = IO::File->new($path, 'r');
        if ($fh) {
            if (my $mime_type = $mime_types->mimeTypeOf($path)) {
                $c->res->header('Content-Type' => $mime_type->type);
            }
            $c->res->header('Content-Length' => $file->{size});
            $c->res->header('Last-Modified' => HTTP::Date::time2str($file->{mtime}));
            binmode $fh;
            $c->res->body($fh);
        } else {
            $c->stash->{'format'} = 'html';
            $c->stash->{status} = 'INTERNAL SERVER ERROR';
            $c->res->status(500);
        }
    } else {
        $c->stash->{'format'} = 'html';
        $c->res->status(404);
    }
}

sub end :Private {
    my ( $self, $c ) = @_;

}

__PACKAGE__->meta->make_immutable;

1;
