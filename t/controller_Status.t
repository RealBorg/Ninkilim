use strict;
use warnings;
use Test::More;


use Catalyst::Test 'Ninkilim';
use Ninkilim::Controller::Status;

ok( request('/status')->is_success, 'Request should succeed' );
done_testing();
