use warnings;
use strict;

package BarnOwl::View;

use BarnOwl::View::Iterator;

our %view_cache;

sub message_deleted {
    my $class = shift;
    my $id = shift;
    for my $view (values %view_cache) {
        $view->message($id, 0);
    }
}

sub get_name   {shift->{name}};
sub message {
    my $self = shift;
    my $idx = shift;
    my $val = shift;
    if(defined $val) {
        vec($self->{messages}, $idx, 1) = $val;
    }
    return vec($self->{messages}, $idx, 1);
};
sub get_filter {shift->{filter}};

sub next_fwd      {shift->{next_fwd}};
sub next_bk       {shift->{next_bk}};
sub at_start      {shift->{at_start}};
sub at_end        {shift->{at_end}};
sub is_empty      {shift->{is_empty}};

sub new {
    my $class = shift;
    my $name = shift;
    my $filter = shift;
    if(defined($view_cache{$filter})) {
        my $self = $view_cache{$filter};
        return $self;
    }

    my $self  = {messages  => "",
                 name      => $name,
                 filter    => $filter,
                 is_empty  => 1};
    bless $self, $class;
    $self->reset;
    $view_cache{$filter} = $self;
    return $self;
}

sub consider_message {
    my $self = shift;
    my $msg = shift;
    for (values %view_cache) {
        $_->_consider_message($msg);
    }
}

sub _consider_message {
    my $self = shift;
    my $msg  = shift;
    return unless $self->at_end;
    if(BarnOwl::filter_message_match($self->get_filter, $msg)) {
        $self->message($msg->{id}, 1);
        $self->{is_empty} = 0;
    }
    $self->{next_fwd} = $msg->{id} + 1;
}

sub reset_all {
    my $self = shift;
    $self->reset;
    %view_cache = ();
}

sub reset {
    my $self = shift;
    $self->{messages} = "";
    $self->{at_start} = $self->{at_end} = 0;
    $self->{next_fwd} = $self->{next_bk} = -1;
}

sub recalculate_around {
    my $self = shift;
    my $where = shift;
    BarnOwl::debug("recalulate @{[$self->get_filter]} around $where");
    if($where == 0) {
        return if $self->at_start;
        $self->{at_start} = 1;
        $self->{at_end}   = 0;
        $self->{next_bk}  = -1;
        $self->{next_fwd} = 0;
    } elsif($where < 0) {
        return if $self->at_end;
        $self->{at_start} = 0;
        $self->{at_end}   = 1;
        $self->{next_bk}  = -1;
        $self->{next_fwd} = undef;
    } else {
        if(defined($self->next_fwd) &&
           defined($self->next_bk) &&
           $self->next_fwd > $where &&
           $self->next_bk < $where) {
            BarnOwl::debug("Hit cache for @{[$self->get_filter]}");
            return;
        } else {
            $self->{at_end} = $self->{at_start} = 0;
            $self->{next_fwd} = $where;
            $self->{next_bk} = $where - 1;
        }
    }
    $self->{is_empty} = 1;
    $self->{messages} = "";
    $self->fill_forward;
    $self->fill_back;
}

my $FILL_STEP = 100;

sub fill_back {
    my $self = shift;
    return if $self->at_start;
    my $pos  = $self->next_bk;
    BarnOwl::debug("Fill back from $pos...");
    my $ml   = BarnOwl::message_list();
    $ml->iterate_begin($pos, 1);
    my $count = 0;
    my $m;
    while($count++ < $FILL_STEP) {
        $m = $ml->iterate_next;
        $self->{next_fwd} = $m->{id} + 1 unless defined $self->{next_fwd};
        unless(defined $m) {
            BarnOwl::debug("Hit start in fill_back.");
            $self->{at_start} = 1;
            last;
        }
        if(BarnOwl::filter_message_match($self->get_filter, $m)) {
            $self->{is_empty} = 0;
            $self->message($m->{id}, 1);
        }
        $self->{next_bk} = $m->{id} - 1;
    }
    $ml->iterate_done;
}

sub fill_forward {
    my $self = shift;
    return if $self->at_end;
    my $pos  = $self->next_fwd;
    BarnOwl::debug("Fill forward from $pos...");
    my $ml   = BarnOwl::message_list();
    $ml->iterate_begin($pos, 0);
    my $count = 0;
    my $m;
    while($count++ < $FILL_STEP) {
        $m = $ml->iterate_next;
        unless(defined $m) {
            $self->{at_end} = 1;
            last;
        }
        if(BarnOwl::filter_message_match($self->get_filter, $m)) {
            $self->{is_empty} = 0;
            $self->message($m->{id}, 1);
        }
        $self->{next_fwd} = $m->{id} + 1;
    }
    $ml->iterate_done;
    BarnOwl::debug("After fill, at @{[$self->next_fwd]}: " . unpack("b*", $self->{messages}));
}

sub invalidate_filter {
    my $filter = shift;
    delete $view_cache{$filter};
}

1;
