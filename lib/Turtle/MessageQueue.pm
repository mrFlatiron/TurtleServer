package Turtle::MessageQueue;
use utf8;
use strict;
use warnings;
use IO::Socket;
use Turtle::UserBox;
use Data::Dumper;
use Encode;

my $instance = undef;

sub new {
  my $class = shift;
  return $instance if $instance;
  $instance = {queue => [], @_};
  bless $instance, $class;
}

sub add {
  my ($self, $message) = @_;
  $message = Encode::encode_utf8($message);
  push @{$instance->{queue}}, $message;
  $self->sendEveryone;
}

sub getInstance {
  return $instance;
}

sub sendEveryone {
  my ($self) = @_;
  my $userBox = Turtle::UserBox->getInstance;
  my @userIDs = keys %{$userBox->{users}};
  my $msg = shift @{$instance->{queue}};
  my $packed_msg = pack ("s/a", $msg);
  for my $userID (@userIDs) {
    $self->sendToUser({userID => $userID,
                       message => $packed_msg,
                       packed => 1});
  }
  print STDERR  Encode::decode_utf8($msg) . "\n";
}

sub sendToUser {
  my ($self, $args) = @_;

  my $userID = $args->{userID};
  my $message = $args->{message};
  my $user = $args->{user};


  if ($userID) {
    $user = Turtle::UserBox->getInstance->{users}->{$userID}; 
  } 

  unless ($args->{packed}) {
    $message = pack ("s/a", $message);
  }

  my $len = length $message;

  if ($len != syswrite($user->{socket}, $message, $len)) {
    warn "Couldn't write to user ". $user->{socket}->peerhost . "\n";
  }

}

1;


