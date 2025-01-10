#!/usr/bin/perl
use File::Slurp;
use JSON;
use POSIX;
use Time::HiRes;

use FindBin qw/$RealBin/;
use lib "$RealBin/../lib";
use Ninkilim::Model::Checkit;

use strict;
use warnings;

while (1) {
    my $nextrun = Time::HiRes::time + 5 * 60;
    my $result = Ninkilim::Model::Checkit->run_checks;
    $result = JSON::encode_json($result);
    File::Slurp::write_file("$RealBin/../root/checkit.json", $result);
    STDOUT->printf(
        "Next run at %s\n", 
        POSIX::strftime('%Y-%m-%dT%H:%M:%S', gmtime($nextrun)),
    );
    my $sleep = $nextrun - Time::HiRes::time;
    Time::HiRes::sleep($sleep) if $sleep > 0;
}
