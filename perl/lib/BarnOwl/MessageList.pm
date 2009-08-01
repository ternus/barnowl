use strict;
use warnings;

package BarnOwl::MessageList;

my $__next_id = 0;

sub next_id {
    return $__next_id++;
}

sub new {
    my $class = shift;
    my $self = {messages => {}};
    return bless $self, $class;
}

sub get_size {
    my $self = shift;
    return scalar keys %{$self->{messages}};
}

sub start_iterate {
    my $self = shift;
    $self->{keys} = [sort {$a <=> $b} keys %{$self->{messages}}];
    $self->{iterator} = 0;
}

sub iterate_next {
    my $self = shift;
    if($self->{iterator} >= scalar @{$self->{keys}}) {
        return undef;
    }
    return $self->get_by_id($self->{keys}->[$self->{iterator}++]);
}

sub get_by_id {
    my $self = shift;
    my $id = shift;
    return $self->{messages}{$id};
}

sub add_message {
    my $self = shift;
    my $m = shift;
    $self->{messages}->{$m->id} = $m;
}

sub expunge {
    my $self = shift;
    for my $message (values %{$self->{messages}}) {
        if($message->is_deleted) {
            delete $self->{messages}->{$message->id};
        }
    }
}

1;
