#!/usr/bin/env perl
use File::Basename;
use Test::More;

my $tester = dirname($0) . "/../tester";
if(! -x $tester) {
    plan skip_all => "Tester not built";
    exit 0;
}
exec(dirname($0) . "/../tester");
