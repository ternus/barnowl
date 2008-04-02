use warnings;
use strict;

package BarnOwl::View;

use BarnOwl::View::Iterator;

sub get_name   {shift->{name}};
sub messages   {shift->{messages}};
sub get_filter {shift->{filter}};

sub at_start   {shift->{at_start}};
sub at_end     {shift->{at_end}};
sub offset     {shift->{offset}};

sub new {
    my $class = shift;
    my $name = shift;
    my $filter = shift;
    my $self  = {messages  => [],
                 name      => $name,
                 filter    => $filter};
    bless $self, $class;
    $self->recalculate;
    return $self;
}

sub consider_message {
    my $self = shift;
    my $msg  = shift;
    return unless $self->at_end;
    if(BarnOwl::filter_message_match($self->get_filter, $msg)) {
        push @{$self->messages}, $msg;
    }
}

sub recalculate {
    my $self = shift;
    $self->{messages} = [];
    $self->{at_start} = $self->{at_end} = 0;
    $self->{offset} = 0;
}

sub recalculate_around {
    my $self = shift;
    my $where = shift;
    if($where == 0) {
        $self->{at_start} = 1;
        $self->fill_forward(0);
    } elsif($where < 0) {
        $self->{at_end} = 1;
        $self->fill_back(-1);
    } else {
        $self->fill_back($where);
        $self->fill_forward;
    }
}

my $FILL_STEP = 100;

sub fill_back {
    my $self = shift;
    my $pos  = shift || $self->messages->[0] - 1;
    my $ml   = BarnOwl::message_list();
    return if $self->at_start;
    $ml->iterate_begin($pos, 1);
    my $count = 0;
    while($count < $FILL_STEP) {
        my $m = $ml->iterate_next;
        unless(defined $m) {
            $self->{at_start} = 1;
            last;
        }
        if(BarnOwl::filter_message_match($self->get_filter, $m)) {
            $self->{offset}++;
            $count++;
            unshift @{$self->messages}, $m
        }
    }
    $ml->iterate_done;
}

sub fill_forward {
    my $self = shift;
    my $pos  = shift || $self->messages->[-1] + 1;
    my $ml   = BarnOwl::message_list();
    return if $self->at_end;
    $ml->iterate_begin($pos, 0);
    my $count = 0;
    while($count < $FILL_STEP) {
        my $m = $ml->iterate_next;
        unless(defined $m) {
            $self->{at_end} = 1;
            last;
        }
        if(BarnOwl::filter_message_match($self->get_filter, $m)) {
            $count++;
            push @{$self->messages}, $m
        }
    }
    $ml->iterate_done;
}

sub new_filter {
    my $self = shift;
    my $filter = shift;
    $self->{filter} = $filter;
    $self->recalculate;
}

sub is_empty {
    my $self = shift;
    return $self->_size == 0;
}

sub _size {
    my $self = shift;
    return scalar @{$self->messages};
}

1;
