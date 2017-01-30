package Turtle::Config;
use utf8;
use strict;
use warnings;
use JSON::XS;

my $config = undef;

sub new {
  return $config if $config;
  $config = {};
  bless $config, shift;
}

sub getConfig {
  my $self = shift;
  if ($config->{initialized}) {
    return $config;
  }
  open (my $fh, "<", "/home/Vyacheslav/chatServer/config.json") or die $!;
  my $jsonxs = JSON::XS->new->utf8->relaxed;
  my $input;
  while (my $str = <$fh>) {
    $input .= $str;
  }
  $config = $jsonxs->decode($input);
  $config->{initialized} = 1;
  return $config;
}
1;
