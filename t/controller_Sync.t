use strict;
use warnings;
use Test::More;


use Catalyst::Test 'Ninkilim';
use Ninkilim::Controller::Sync;

ok( request('/sync')->is_success, 'Request should succeed' );
done_testing();
