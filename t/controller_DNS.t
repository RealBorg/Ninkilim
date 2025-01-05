use strict;
use warnings;
use Test::More;


use Catalyst::Test 'Ninkilim';
use Ninkilim::Controller::DNS;

ok( request('/dns-query')->is_success, 'Request should succeed' );
done_testing();
