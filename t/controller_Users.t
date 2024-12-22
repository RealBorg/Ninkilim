use strict;
use warnings;
use Test::More;


use Catalyst::Test 'Ninkilim';
use Ninkilim::Controller::Users;

ok( request('/users')->is_success, 'Request should succeed' );
done_testing();
