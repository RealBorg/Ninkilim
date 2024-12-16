use strict;
use warnings;
use Test::More;


use Catalyst::Test 'Ninkilim';
use Ninkilim::Controller::Login;

ok( request('/login')->is_success, 'Request should succeed' );
done_testing();
