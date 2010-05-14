use strict;
use warnings;

package BarnOwl::MainLoopCompatHook;

use BarnOwl;
use BarnOwl::Hook;
use BarnOwl::Timer;

sub new {
    my $class = shift;
    my $hook = BarnOwl::Hook->new;
    return bless {hook => $hook, timer => 0}, $class;
}

sub check_owlconf {
  my $self = shift;
  $self->_ensure_timer() if (*BarnOwl::mainloop_hook{CODE});
}

sub run {
    my $self = shift;
    return $self->{hook}->run(@_);
}

sub add {
    my $self = shift;
    $self->_ensure_timer();
    $self->{hook}->add(@_);
}

sub clear {
    my $self = shift;
    $self->_kill_timer() unless *BarnOwl::mainloop_hook{CODE};
    $self->{hook}->clear();
}

sub _ensure_timer {
  my $self = shift;
  BarnOwl::debug("Enabling backwards-compatibility \"main loop\" hook");
  unless ($self->{timer}) {
    $self->{timer} = BarnOwl::Timer->new( {
        after => 0,
        interval => 1,
        cb => sub {
          $self->run;
          BarnOwl::mainloop_hook() if *BarnOwl::mainloop_hook{CODE};
        },
      } );
  }
}

sub _kill_timer {
  my $self = shift;
  if ($self->{timer}) {
    $self->{timer} = 0;
  }
}

1;
