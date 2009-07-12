#!/usr/bin/env perl
use File::Basename;
use Test::More;

my $root = dirname($0) . "/..";

my $tester = "$root/tester";
if(! -x $tester) {
    plan skip_all => "Tester not built";
    exit 0;
}
$ENV{BARNOWL_DATA_DIR} = "$root/perl";

exec(dirname($0) . "/../tester");
