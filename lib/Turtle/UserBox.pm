package Turtle::UserBox;
use utf8;
use strict;
use warnings;
use Data::Dumper;
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
  if ($self->{count} + 1 > Turtle::Config->getConfig->{maxConnections}) {
    return Turtle::Const::Server::SERVER_FULL();
  }
  $self->{maxID}++;
  my $id = $self->{maxID};
  $self->{users}->{$id} = $user;
  $user->{ID} = $id; 
  $self->{count}++;
  return 0;
}

sub delete {
  my ($self, $userID) = @_;
  if (exists $self->{users}->{$userID}) {
    delete $self->{users}->{$userID};
    $self->{count}--;
  }
  return $self;
}

sub closeAll {
  my ($self) = @_;
  for my $userID (keys %{$self->{users}}) {
    my $user = $self->{users}->{$userID};
    $user->closeConnection;
  }
  $self->{maxID} = 0;
  return $self;
}

sub nameCheck {
  my ($self, $name) = @_;
  return 1 if $self->{count} == 1;
  return 1 unless $self->getByName($name);
  return 0;
}

sub getByID {
  my ($self, $ID) = @_;
  my $user = $self->{users}->{$ID};
  return $user;
}

sub getByName {
  my ($self, $name) = @_;
  my $user;
  my ($userID) = grep {($user = $self->getByID($_)) and $user->{name} eq $name} keys %{$self->{users}};
  my $user = $self->getByID($userID) if $userID;
  return $user;
}

1;
