use strict;
use warnings;
use Test::More;


use Catalyst::Test 'Ninkilim';
use Ninkilim::Controller::Articles;

ok( request('/articles')->is_success, 'Request should succeed' );
done_testing();
