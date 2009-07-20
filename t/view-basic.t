#!/usr/bin/env perl
use strict;
use warnings;

use Test::More qw(no_plan);
use File::Basename;

=head1 DESCRIPTION

Test for basic functionality of BarnOwl::View and
BarnOwl::View::Iterator

=cut

BEGIN {
    require (dirname($0) . "/mock.pl");
};

my $ml = BarnOwl::message_list;

for my $i (0..100) {
    $ml->add_message(
        BarnOwl::Message->new(
            type => 'generic',
            num  => $i));
}

my $view;
my $it;

$view = BarnOwl::View->new('all');
is($view->get_filter, 'all');

ok(!$view->is_empty);

is(BarnOwl::View->new('all'), $view, "View->new is memoized");

######

$it = BarnOwl::View::Iterator->new();

$it->initialize_at_start($view);
ok($it->is_at_start, "initialize_at_start is at start");
ok(!$it->is_at_end, "initialize_at_start is not at end");

$it->initialize_at_end($view);
ok(!$it->is_at_start, "initialize_at_end is not at start");
ok($it->is_at_end, "initialize_at_end is at end");

######
diag("Do a basic iteration...");

$it->initialize_at_start($view);

for my $i (0..100) {
    my $m = $it->get_message;
    is($m->{num}, $i);
    ok(!$it->is_at_end);
    $it->next;
    ok(!$it->is_at_start);
}

is($it->get_message, undef);
ok($it->is_at_end, "Iterator after iteration is at end");

diag("Do a reverse iteration...");

BarnOwl::View::invalidate_filter('all');
$view = BarnOwl::View->new('all');

$it->initialize_at_end($view);

is($it->get_message, undef);

for my $i (0..100) {
    $it->prev;
    my $m = $it->get_message;
    is($m->{num}, 100-$i);
}

ok($it->is_at_start);

#####
# Empty view is empty

$view = BarnOwl::View->new('none');
ok($view->is_empty, "Empty view is empty");

$it->initialize_at_start($view);
ok($it->is_at_start, "at_start on empty view is at start");
ok($it->is_at_end,   "at_start on empty view is at end");

$it->initialize_at_end($view);
ok($it->is_at_start, "at_end on empty view is at end");
ok($it->is_at_end, "at_end on empty view is at end");

### Simultaneous iteration works

BarnOwl::View::invalidate_filter('all');
$view = BarnOwl::View->new('all');

my $i1 = BarnOwl::View::Iterator->new;
my $i2 = BarnOwl::View::Iterator->new;

$i1->initialize_at_start($view);
$i2->initialize_at_end($view);

for my $i (0..100) {
    $i2->prev;
    my $m2 = $i2->get_message;
    
    my $m1 = $i1->get_message;
    $i1->next;

    is($m1->{num}, $i);
    is($m2->{num}, 100-$i);
}

### Test a sparser view

my $primes = BarnOwl::View->new('prime');
$it->initialize_at_start($primes);

is($it->get_message->{num}, 2);

for my $i (qw(2 3 5 7 11 13 17 19 23 29 31 37 41
              43 47 53 59 61 67 71 73 79 83 89 97)) {
    is($it->get_message->{num}, $i);
    $it->next;
}

ok($it->is_at_end);

### Interaction with deletion

BarnOwl::View::invalidate_filter('all');
$view = BarnOwl::View->new('all');

$it->initialize_at_start($view);
$it->get_message->delete;
BarnOwl::message_list()->expunge;

isnt($it->get_message, $it, "Deleted message is not returned");
is($it->get_message->{num}, 1, "Next message is returned after delete.");

$it->next;
is($it->get_message->{num}, 2);
$it->get_message->delete;
BarnOwl::message_list()->expunge;
$it->next;
is($it->get_message->{num}, 4);

$it->initialize_at_end($view);
$it->prev;

$it->get_message->delete;
BarnOwl::message_list()->expunge;

is($it->get_message, undef);
ok($it->is_at_end, "Deleting last messages moves iterator to end.");
