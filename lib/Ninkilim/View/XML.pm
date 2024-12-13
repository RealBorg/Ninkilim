package Ninkilim::View::XML;
use Moose;
use namespace::autoclean;
use XML::Simple;

extends 'Catalyst::View';

sub process {
    my ($self, $c) = @_;

    my $xmlopts = $c->stash->{xmlopts};
    delete $c->stash->{xmlopts};
    my $xml = { %{$c->stash} };
    $xml = XMLout($xml, %{$xmlopts});
        #NoAttr   => 1,  # Avoid attributes, use only elements
        #RootName => 'xml',  # Root element name
        #XMLDecl  => 1,  # Include XML declaration
    $c->response->content_type('application/xml');
    $c->response->body($xml);

    return 1;
}


__PACKAGE__->meta->make_immutable;

1;
