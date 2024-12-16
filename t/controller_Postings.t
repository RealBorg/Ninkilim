use strict;
use warnings;
use Test::More;


use Catalyst::Test 'Ninkilim';
use Ninkilim::Controller::Postings;

ok( request('/postings')->is_success, 'Request should succeed' );
done_testing();
