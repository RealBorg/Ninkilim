package Ninkilim::Email;

use MIME::Lite;
use base 'MIME::Lite';

use strict;
use warnings;

use constant {
    FROM => 'ninkilim@hostmaster.org',
};

sub new {
    my $class = shift;
    my $params = { 
        From => FROM(),
        @_,
    };

    return $class->SUPER::new(%{$params});
}

1;
