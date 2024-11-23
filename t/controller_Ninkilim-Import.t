use strict;
use warnings;
use Test::More;


use Catalyst::Test 'Ninkilim';
use Ninkilim::Controller::Ninkilim::Import;

ok( request('/ninkilim/import')->is_success, 'Request should succeed' );
done_testing();
