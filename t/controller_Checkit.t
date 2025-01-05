use strict;
use warnings;
use Test::More;


use Catalyst::Test 'Ninkilim';
use Ninkilim::Controller::Checkit;

ok( request('/checkit')->is_success, 'Request should succeed' );
done_testing();
