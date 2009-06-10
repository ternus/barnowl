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

$view = BarnOwl::View->new('all', 'all');

$i1 = BarnOwl::View::Iterator->new;
$i2 = BarnOwl::View::Iterator->new;

# cmp() normalizes correctly

$i1->initialize_at_start($view);
$i2->initialize_at_start($view);

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

$view = BarnOwl::View->new('one', 'one');
ok(!$view->is_empty, "View with one message is not empty");

$i1->initialize_at_start($view);

ok(!$i1->is_at_end, "With one message, start != end");

$i1->get_message->delete;
BarnOwl::message_list()->expunge;

ok($i1->is_at_end, "Deleting only message moves start iterator to end");
ok($i1->is_at_start, "Start iterator still at start.");

ok($view->is_empty, "Deleting last message empties view");
