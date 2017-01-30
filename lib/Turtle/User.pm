package Turtle::User;
use utf8;
use strict;
use warnings;
use lib "/home/Vyacheslav/chatServer/lib";
use Data::Dumper;
use IO::Socket;
use AnyEvent;
use Turtle::MessageQueue;
use Turtle::UserBox;
use Turtle::Const;
use Turtle::Const::Server;
use Encode;


sub new {
  my $self = {};
  bless $self, shift;
  $self->setBufEmpty;
  return $self;
}

sub bindSocket {
  my ($self, $socket) = @_;

  $self->{socket} = $socket;
  $self->{name} = '';

  my $watcher_recv = AnyEvent->io(
    fh => $socket,
    poll => 'r',
    cb => sub {$self->msgRecv(@_);}
  );

  $self->{watcher} = $watcher_recv;
  return $self;
}

sub msgRecv {
  my $self = shift;
  my $msg_length = 0;

  if ($self->{lengthExpected} == 0) {
    my $len_check;
    $len_check = sysread($self->{socket}, $msg_length, 2);

    if ($len_check == 0) {
      $self->closeConnection("Closed connection");
      return 0;
    }
    if ($len_check != 2) {
      $self->closeConnection("Message is too short");
      return 0;
    }

    $msg_length = unpack ("s", $msg_length);
    warn "msg_length = " . $msg_length;
    if ($msg_length > Turtle::Const::MAX_MESSAGE_LENGTH_BYTES) {
      $self->closeConnection("Message length limit exceeded");
      return 0;
    }
    if ($msg_length <= 0) {
      $self->closeConnection("Message length invalid");
      return 0;
    }

    $self->{lengthExpected} = $msg_length;
    $self->{msgRecieved} = '';
    $self->{lengthRecieved} = 0;
  }

  
  my $message_temp;

  my $length_recieved_temp = sysread($self->{socket}, $message_temp, $self->{lengthExpected} - $self->{lengthRecieved});

  if ($length_recieved_temp == 0) {
    $self->closeConnection("Closed Connection");
    return 0;
  }

  $self->{lengthRecieved} += $length_recieved_temp;
  $self->{msgRecieved} .= $message_temp;

  return 0 if $self->{lengthRecieved} < $self->{lengthExpected};

  $self->{msgRecieved} = unpack ('a' . $self->{lengthRecieved}, $self->{msgRecieved});
  $self->{msgRecieved} = Encode::decode_utf8($self->{msgRecieved});

  while (chomp $self->{msgRecieved}) {};

  unless ($self->{name}) {
    my $name = $self->{msgRecieved};
    return 0 unless $self->setName($name);
    return 1;
  }

  my $msg_with_name = $self->{name} . ": " . $self->{msgRecieved};

  $self->setBufEmpty;

  Turtle::MessageQueue->add($msg_with_name);
  return 1;
}

sub closeConnection {
  my ($self, $log) = @_;
  warn "[" . $self->{socket}->peerhost . " <-> '" . $self->{name} . "']: " . $log . "\n" if $log;
  close $self->{socket} if $self->{socket}->connected();
  undef $self->{watcher} if $self->{watcher};
  Turtle::UserBox->delete($self->{ID}) if $self->{ID};
}

sub setBufEmpty {
  my $self = shift;
  $self->{msgRecieved} = '';
  $self->{lengthExpected} = 0;
  $self->{lengthRecieved} = 0;
}

sub setName {
  my ($self, $name) = @_;

  if (length $name > Turtle::Const::MAX_USERNAME_LENGTH_UTF8()) {
      $self->kick(Turtle::Const::Server::USERNAME_TOO_LONG());
      return 0;
    }

  if (Turtle::UserBox->nameCheck($name)) {
    $self->{name} = $name;
    $self->setBufEmpty;
    warn "[" . $self->{socket}->peerhost . "]: Set username to '" . $self->{name} . "'\n";
    return 1;
  }
  
  $self->kick(Turtle::Const::Server::USERNAME_TAKEN());
  return 0;
}

sub setUsername {
  shift->setName(@_);
}

sub kick {
  my ($self, $error_const) = @_;

  my $message = Turtle::Const::Server::errorToText($error_const);
  my $len = - length(Encode::encode_utf8($message));
  my $packed_msg .= pack("s", $len);
  $len = - $len;
  $packed_msg .= pack ("a" . $len, $message);
  Turtle::MessageQueue->sendToUser({user => $self,
      message => $packed_msg,
      packed => 1});
  $self->closeConnection("kicked. Reason : " . $message);
}

1;
