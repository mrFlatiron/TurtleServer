package Turtle::UserBox;
use utf8;
use strict;
use warnings;
use Turtle::User;
use Turtle::Config;
use Turtle::Const::Server;

my $instance = undef;

sub new {
  my $class = shift;
  return $instance if $instance;
  $instance = {users => {}, count => 0, maxID => 0};
  bless $instance, $class;
}

sub getInstance {
  return $instance;
}

sub add {
  my ($self, $user) = @_;
  if ($instance->{count} + 1 > Turtle::Config->getConfig->{maxConnections}) {
    return Turtle::Const::Server::SERVER_FULL();
  }
  $instance->{maxID}++;
  my $id = $instance->{maxID};
  $instance->{users}->{$id} = $user;
  $user->{ID} = $id; 
  $instance->{count}++;
  return 0;
}

sub delete {
  my ($self, $userID) = @_;
  if (exists $instance->{users}->{$userID}) {
    delete $instance->{users}->{$userID};
    $instance->{count}--;
  }
  return $instance;
}

sub closeAll {
  my ($self) = @_;
  for my $userID (keys %{$instance->{users}}) {
    my $user = $instance->{users}->{$userID};
    $user->closeConnection;
  }
  $instance->{maxID} = 0;
  return $instance;
}

sub nameCheck {
  my ($self, $name) = @_;
  return 1 if $instance->{count} == 0;
  return (!grep {$instance->{users}->{$_}->{name} eq $name} keys %{$instance->{users}});
}

1;
