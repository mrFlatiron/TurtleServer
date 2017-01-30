package Turtle::Const::Server;

use Turtle::Const;

sub USERNAME_TAKEN           { -100 }
sub SERVER_FULL              { -101 }
sub USERNAME_TOO_LONG        { -102 }


sub errorToText {
  my $error = shift;

  if ($error == USERNAME_TAKEN()) {
    return "That username is already taken. Change it and try to reconnect";
  }
  if ($error == SERVER_FULL()) {
    return "The server is full. Try again later";
  }
  if ($error == USERNAME_TOO_LONG()) {
    return "The username's length must be no more than " . Turtle::Const::MAX_USERNAME_LENGTH_UTF8() . " characters";
  }

  return '';
}

1;
