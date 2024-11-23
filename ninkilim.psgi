use strict;
use warnings;

use Ninkilim;

my $app = Ninkilim->apply_default_middlewares(Ninkilim->psgi_app);
$app;

