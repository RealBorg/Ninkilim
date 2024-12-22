use strict;
use warnings;
use Test::More;


use Catalyst::Test 'Ninkilim';
use Ninkilim::Controller::Sync::Run;

ok( request('/sync/run')->is_success, 'Request should succeed' );
done_testing();
