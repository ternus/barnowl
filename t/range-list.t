#!/usr/bin/env perl
use strict;
use warnings;

use Test::More qw(no_plan);

use File::Basename;
BEGIN {
    require (dirname($0) . "/mock.pl");
};

my $range = BarnOwl::View::RangeList->new(-1,-1);
my $r1;

$r1 = $range->find_or_insert(10);
is($r1->next_bk, 10);
is($r1->next_fwd, 10);
is($range->next, $r1);
is($r1->prev, $range);

ok(!$r1->expand_fwd(20), "Simple expand returns false");
is($r1->next_fwd, 20);
is($r1->next, undef, "Simple expand doesn't create a new range.");

is($r1->find_or_insert(15), $r1);

# Insert a new range later on
my $r2 = $range->find_or_insert(30);
isnt($r1, $r2);
is($r2->prev, $r1);
is($r1->next, $r2);

is($r2->next_bk, 30);
is($r2->next_fwd, 30);

# Expand it slightly
ok(!$r2->expand_bk(25), "Simple expand returns false");
is($r2->next_bk, 25);

# Expand it to overlap the second range
ok($r2->expand_bk(15), "Merged expand returns true");
is($r2->next_bk, 10);
is($r2->next, undef);
is($r2->prev, $range);
is($range->next, $r2);

is($range->find_or_insert(20), $r2);

# Insert a range at 'infinity'
my $r3 = $range->find_or_insert(-1);
is($range->find_or_insert(-1), $r3);

is($r3->prev, $r2);
is($r2->next, $r3);

$r3->expand_bk(50);
is($r3->next_bk, 50);
is($r3->next_fwd, undef);
$r3->expand_fwd(51);
is($r3->next_fwd, 51);

# Check edge cases on find_or_insert
# r2 -- (10,30)
# r3 -- (50,51)
is($range->find_or_insert(10), $r2);
is($range->find_or_insert(30), $r2);

is($range->find_or_insert(50), $r3);
is($range->find_or_insert(51), $r3);

my $r = $range->find_or_insert(9);
isnt($r, $r2);
ok($r->expand_fwd);
is($r->next_fwd, 30);

# Test merging

$range = BarnOwl::View::RangeList->new(-1,-1);

for my $i (10..20) {
    my $r = $range->find_or_insert($i);
    is($r->next_fwd, $i);
    is($r->next_bk, $i);
}

$r3 = $range->find_or_insert(-1);

$r = $range->find_or_insert(0);
ok($r->expand_fwd(20));

is($range->next, $r);
is($r->next, $r3);
is($r3->prev, $r);


$range = BarnOwl::View::RangeList->new(-1,-1);

$r = $range->find_or_insert(10);
$r1 = $range->find_or_insert(11);
isnt($r, $r1);
$r1->expand_bk;

is($range->next, $r1);
is($r1->next_fwd, 11);
is($r1->next_bk, 10);
