use warnings;
use strict;

package BarnOwl::View;

use BarnOwl::View::Iterator;

sub get_name   {return shift->{name}};
sub messages   {return shift->{messages}};
sub get_filter {return shift->{filter}};

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
    if(BarnOwl::filter_message_match($self->get_filter, $msg)) {
        push @{$self->messages}, $msg;
    }
}

sub recalculate {
    my $self = shift;
    my $ml   = BarnOwl::message_list();
    $ml->start_iterate;
    $self->{messages} = [];
    while(my $msg = $ml->iterate_next) {
        $self->consider_message($msg);
    }
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
