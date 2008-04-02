use strict;
use warnings;

package BarnOwl::View::Iterator;

sub view {return shift->{view}}
sub index {return shift->{index}}
sub eff_index {
    my $self = shift;
    return $self->index + $self->view->offset;
}

sub new {
    my $class = shift;
    my $self = {
        view  => undef,
        index => undef
       };
    return bless $self, $class;
}

sub invalidate {
    my $self = shift;
    $self->{view} = undef;
    $self->{index} = undef;
}

sub initialize_at_start {
    my $self = shift;
    my $view = shift;
    $self->{view}  = $view;
    $self->{index} = 0;
    $view->recalculate_around(0);
}

sub initialize_at_end {
    my $self = shift;
    my $view = shift;
    $self->{view}  = $view;
    $self->{index} = 0;
    $view->recalculate_around(-1);
}

sub initialize_at_id {
    my $self = shift;
    my $view = shift;
    my $id   = shift;
    $self->{view} = $view;
    $self->{index} = 0;
    $view->recalculate_around($id);
}

sub clone {
    my $self = shift;
    my $other = shift;
    $self->{view} = $other->{view};
    $self->{index} = $other->{index};
}

sub has_prev {
    my $self = shift;
    $self->fill_back;
    return $self->index > 0;
}

sub has_next {
    my $self = shift;
    $self->fill_forward;
    return $self->index < $self->view->_size - 1;
}

sub at_start {
    my $self = shift;
    $self->fill_back;
    return $self->index < 0;
}

sub at_end {
    my $self = shift;
    $self->fill_forward;
    return $self->index >= $self->view->_size;
}


sub valid {
    my $self = shift;
    return defined($self->view) &&
            !$self->at_start &&
            !$self->at_end;
}

sub prev {
    my $self = shift;
    $self->{index}-- unless $self->at_start
}

sub next {
    my $self = shift;
    $self->{index}++ unless $self->at_end
}

sub get_message {
    my $self = shift;
    return $self->view->messages->[$self->eff_index];
}

sub fill_back {
    my $self = shift;
    if($self->eff_index == 0) {
        $self->view->fill_back;
    }
}

sub fill_forward {
    my $self = shift;
    if($self->eff_index == (scalar @{$self->view->messages}) - 1) {
        $self->view->fill_forward;
    }
}

sub cmp {
    my $self = shift;
    my $other = shift;
    return $self->index - $other->index;
}

1;
