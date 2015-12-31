#!/usr/bin/perl -w
use strict;
use v5.10;
$| =0;

my $sleep = 0.25;

use Time::Piece;
use Time::HiRes;
use POSIX qw/strftime/;

my $err = 0;
my $ok = 0;

$SIG{INT} = sub { say "Successful Queries: $ok Failed: $err"; exit 0; };
say "Starting up with $sleep sleep between queries";
while (1) {
  my $ip = '';
  my $t = Time::HiRes::time;
  my $s = sprintf "%06.3f", $t-int($t/60)*60;
  my $ts = strftime "%H:%M:$s ", localtime $t;
  my @cmd = `host -s -t A -W 1 -t A -R 0 app.goclio.com 64.202.97.1`;
  for (@cmd) {
    if (/has address ([0-9\.]+)$/) {
      $ok++;
      $ip = $1;
      unless ($ok % 10) {
        say "$ts: $ok OK, $err errors";
      }
      Time::HiRes::sleep($sleep); # 4 queries/sec
    }
  }
  if(!$ip) {
    print "$ts: Fail.\n";
    $err++;
  }
}
