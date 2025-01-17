package Ninkilim::View::XML;
use Moose;
use namespace::autoclean;
use XML::Simple;

extends 'Catalyst::View';

use strict;
use warnings;
use bytes;

sub process {
    my ($self, $c) = @_;

    my $xmlopts = $c->stash->{'xmlopts'};
    unless ($xmlopts) {
       $xmlopts = {
        NoAttr   => 1,  # Avoid attributes, use only elements
        RootName => 'xml',  # Root element name
        XMLDecl  => 1,  # Include XML declaration
       };
    }
    my $data = $c->stash->{'data'};
    $data = XMLout($data, %{$xmlopts});
    $c->res->header('Content-Type', 'application/xml');
    $c->res->header('Content-Length', length($data));
    $c->response->body($data);

    return 1;
}

__PACKAGE__->meta->make_immutable;

1;
