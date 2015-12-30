#!/usr/bin/perl -w
use strict;
use v5.10;
$| =0;

use Time::Piece;

my $err = 0;
my $ok = 0;

while (1) {
  my $ip = '';
#  print localtime->strftime('%Y-%m-%d') . ": ";
  my @cmd = `host -s -t A -W 1 -t A -R 0 app.goclio.com 64.202.97.1`;
  for (@cmd) {
    if (/has address ([0-9\.]+)$/) {
      $ok++;
      $ip = $1;
      print "OK - $ip\n";
    }
  }
  if(!$ip) {
    print "Fail.\n";
    $err++;
  }
}
