package Ninkilim;
use Moose;
use namespace::autoclean;

use Catalyst::Runtime 5.80;

# Set flags and add plugins for the application.
#
# Note that ORDERING IS IMPORTANT here as plugins are initialized in order,
# therefore you almost certainly want to keep ConfigLoader at the head of the
# list if you're using it.
#
#         -Debug: activates the debug mode for very useful log messages
#   ConfigLoader: will load the configuration from a Config::General file in the
#                 application's home directory
# Static::Simple: will serve static files from the application's root
#                 directory

use Catalyst qw/
    -Debug
    ConfigLoader
    Static::Simple
/;

extends 'Catalyst';

our $VERSION = '0.01';

# Configure the application.
#
# Note that settings in ninkilim.conf (or other external
# configuration file that you set up manually) take precedence
# over this when using ConfigLoader. Thus configuration
# details given here can function as a default configuration,
# with an external configuration file acting as an override for
# local deployment.

__PACKAGE__->config(
    name => 'Ninkilim',
    # Disable deprecated behavior needed by old applications
    disable_component_resolution_regex_fallback => 1,
    enable_catalyst_header => 1, # Send X-Catalyst header
    encoding => 'UTF-8', # Setup request decoding and response encoding
    'Plugin::Static::Simple' => {
        include_path => [ __PACKAGE__->config->{root}.'/static' ],
        dirs => [ 'static' ],
    },
);

# Start the application
__PACKAGE__->setup();

sub uri_for {
    my ($self, $path, @args) = @_;

    # Call the superclass's _uri_for method to get the full URI
    my $uri = $self->SUPER::uri_for($path, @args);
    my $base = $uri->scheme.'://'.$uri->host.':'.$uri->port.'/';
    warn $base;
    $uri = $uri->rel($base);
    warn $uri;
    return $uri;
}
=encoding utf8

=head1 NAME

Ninkilim - Catalyst based application

=head1 SYNOPSIS

    script/ninkilim_server.pl

=head1 DESCRIPTION

[enter your description here]

=head1 SEE ALSO

L<Ninkilim::Controller::Root>, L<Catalyst>

=head1 AUTHOR

Thomas Zehetbauer

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
