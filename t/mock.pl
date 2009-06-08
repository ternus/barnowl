use File::Basename;
use lib (dirname($0) . '/../perl/lib');

package BarnOwl;

use strict;
use warnings;
use Carp;

sub bootstrap {}
sub get_data_dir {"."}
sub get_config_dir {"."}
sub create_style {}

our $ml = BarnOwl::MessageList->new();
sub message_list {$ml}

sub debug {
    warn "[DEBUG] ", shift, "\n" if $ENV{TEST_VERBOSE};
}

our %filters;

sub new_filter {
    my $name = shift;
    my $sub = shift;
    BarnOwl::View::invalidate_filter($name);
    $filters{$name} = $sub;
}

sub filter_message_match {
    my $filter = shift;
    my $m = shift;
    unless(exists $filters{$filter}) {
        die("Unknown filter: $filter\n");
    }
    return $filters{$filter}->($m);
}

use BarnOwl;

# Use a smaller fill step for testing so we can test on small message
# lists.
$BarnOwl::View::FILL_STEP = 10;
