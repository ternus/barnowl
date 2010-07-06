#!/usr/bin/env perl
use strict;
use warnings;

use Test::More qw(no_plan);
use File::Basename;

=head1 DESCRIPTION

A place to put regression tests and tests for miscellaneous bugs in
views and view iterators.

=cut

BEGIN {
    require (dirname($0) . "/mock.pl");
};

my $ml = BarnOwl::message_list;

for my $i (0..10) {
    $ml->add_message(
        BarnOwl::Message->new(
            type => 'generic',
            num  => $i));
}

my $view;
my $i1;
my $i2;

BarnOwl::filter('one', 'num', '^1$');

$view = BarnOwl::View->new('all');

$i1 = BarnOwl::View::Iterator->new;
$i2 = BarnOwl::View::Iterator->new;

# cmp() normalizes correctly

$i1->init_start($view);
$i2->init_start($view);

is($i1->cmp($i2), 0);
is($i2->cmp($i1), 0);

$i1->next;

is($i1->cmp($i2), 1);
is($i2->cmp($i1), -1);

$i2->get_message->delete;
BarnOwl::message_list()->expunge;

is($i1->cmp($i2), 0);
is($i2->cmp($i1), 0);


# is_empty updates appropriately.

$view = BarnOwl::View->new('one');
ok(!$view->is_empty, "View with one message is not empty");

$i1->init_start($view);

ok(!$i1->is_at_end, "With one message, start != end");

$i1->get_message->delete;
BarnOwl::message_list()->expunge;

ok($i1->is_at_end, "Deleting only message moves start iterator to end");
ok($i1->is_at_start, "Start iterator still at start.");

ok($view->is_empty, "Deleting last message empties view");

## Iterators don't loop forever on empty message list

my $m;
$ml->iterate_begin(0);
while ($m = ($ml->iterate_next)) {
    $m->delete;
}
$ml->iterate_done;
$ml->expunge;

$view = BarnOwl::View->new('all');
$i1->init_start($view);

ok($i1->is_at_start);
ok($i1->is_at_end);

$i1->next;

ok($i1->is_at_start);
ok($i1->is_at_end);

## Bugs reallocating the message buffer

# views have room to store 32k entries in the bitmap index by default, so
# crossing that forces a reallocation.

$ml->add_message(
    BarnOwl::Message->new(
        type => 'generic',
        num  => 100,
        id   => 100));

$view = BarnOwl::View->new('all');

$i1->init_start($view);
while (!$i1->is_at_end) {
    $i1->next;
}

# And a message at the end of the second page.

$ml->add_message(
    BarnOwl::Message->new(
        type => 'generic',
        num  => 0,
        id   => 65500));

# Iterate that message. This will create a valid range spanning most of both
# pages.

$i1->next;

# Now walk backwards to verify that the newly allocated pages was properly
# cleared.

$i1->prev;
is($i1->get_message->{id}, 65500);
$i1->prev;
is($i1->get_message->{id}, 100);
