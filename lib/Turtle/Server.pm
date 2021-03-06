package Turtle::Server;
use utf8;
use strict;
use warnings;
use IO::Socket;
use AnyEvent;
use Data::Dumper;
use Turtle::Config;
use Turtle::UserBox;
use Turtle::Const::Server;

sub new {
  my $config = Turtle::Config->new->getConfig;
  my $self = {};
  for my $k (keys %$config) {
    $self->{$k} = $config->{$k};
  }
  $self->{userBox} = Turtle::UserBox->new;
  $self->{cv}      = AnyEvent->condvar;

  bless $self, shift;
}

sub start {
  my $self = shift;
  print Dumper($self);

  my $listen_socket = IO::Socket::INET->new(
    LocalAddr => $self->{hostAddress},
    LocalPort => $self->{hostService},
    Proto => 'tcp',
    ReuseAddr => 1,
    ReusePort => 1,
    Blocking => 0,
    Listen => $self->{listenQueueNum},
    Type => SOCK_STREAM,
  );

  die $! unless $listen_socket;

  my $admin_watcher = AnyEvent->io(
    fh => \*STDIN,
    poll => 'r',
    cb => sub {$self->adminAction(@_);}
  );

  my $listen_watcher = AnyEvent->io(
    fh => $listen_socket,
    poll => 'r',
    cb => sub {$self->acceptConnection($listen_socket);}
  );

  warn "Server is running!";

  $self->{cv}->recv;

}

sub adminAction {
  my $self = shift;
  chomp (my $command = <>);
  if ($command eq "Shutdown" or
    $command eq "Quit" or 
    $command eq "Exit" or
    $command eq "Q") {

    $self->{cv}->send;
    $self->{userBox}->closeAll;
    warn "Gracefully shutting down. Goodbye!";
  }
  if ($command =~ /^\s*kick/) {
    $self->kickCommand($command);
  }
}

sub kickCommand {
  my ($self, $command) = @_;
  my ($user_name) = $command =~ /^\s*kick\s+name=(.*)$/;
  unless ($user_name) {
    return 0;
  }
  my $user = $self->{userBox}->getByName($user_name);
  unless ($user) {
    print STDERR "[ERROR]: kick: no user found\n";
    return 0;
  }
  $self->{userBox}->getByName($user_name)->kick(Turtle::Const::Server::BY_ADMIN());
  return 1;
}

sub acceptConnection {
  my ($self, $l_socket) = @_;
  my ($new_socket, $addr) = $l_socket->accept(); 
  unless ($new_socket) {
    warn "Acceptance error";
    return;
  }
  warn "New connection from " . $new_socket->peerhost. "\n";
  my $user = Turtle::User->new->bindSocket($new_socket);
  my $error = $self->{userBox}->add($user);
  warn $error if $error;
  if ($error) {
    $user->kick($error);
  }
}

1;


