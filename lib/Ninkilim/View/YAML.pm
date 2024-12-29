package Ninkilim::View::YAML;
use Moose;
use namespace::autoclean;
use Encode;
use YAML::XS;

extends 'Catalyst::View';

sub process {
    my ($self, $c) = @_;

    my $data = $c->stash->{'data'};
    $data = Dump($data);
    $data = decode('utf8', $data);
    $c->response->content_type('text/yaml; charset=UTF-8');
    $c->res->body($data);

    return 1;
}

__PACKAGE__->meta->make_immutable;

1;
