use strict;
use warnings;
use Test::More;


use Catalyst::Test 'Ninkilim';
use Ninkilim::Controller::Postings::Create;

ok( request('/postings/create')->is_success, 'Request should succeed' );
done_testing();
