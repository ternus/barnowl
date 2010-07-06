#!/usr/bin/env perl
use strict;
use warnings;

use Test::More qw(no_plan);

use File::Basename;
BEGIN {
    require (dirname($0) . "/mock.pl");
};

my $now = time;
my $m = BarnOwl::Message->new(
    type => 'generic'
   );
ok($m, "Created a message");
isa_ok($m, "BarnOwl::Message::Generic", "Message->new blessed into the correct type");
ok(defined($m->{unix_time}), "Message->new set the time");
ok(abs($m->{unix_time} - $now) <= 1, "Message->new set the time to now");
