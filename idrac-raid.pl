#!/usr/bin/perl
# Simple demo script to check the basic RAID health of idrac7/idrac8 PERC RAID

$AUTHOR = 'Phil Doroff <phil@servercentral.com>';
$VERSION = '0.01';

use v5.18;
use Data::Dumper;
use Format::Human::Bytes;
use Getopt::Long qw(:config gnu_getopt);
use Pod::Usage;
my $racadm = '/usr/local/hannibal/bmc-edge-api/bin/idracadm7';

# Defaults
my %opt = (
  'user' => 'root',
  'pass' => 'yomamafat',
);
GetOptions (
  \%opt, 'host|h=s', 'user|u=s', 'pass|p=s', 'help|?'
);
pod2usage(1) if ( ( defined( $opt{'help'} ) ) );

my @out = `$racadm -r $opt{host} -u $opt{user} -p $opt{pass} hwinventory`;

my $instanceid;
my %inv;
for (@out) {
  chomp();
  # Delete spurious DOS newlines
  s/[\r\n]+//;
  
  next if /^\s*$/;
  next if /^-+$/; # Skip seperator lines
  if (/\[InstanceID:\s+([^]]*)/) {
    $instanceid = $1;
  } else {
    # Whitespace is important 
    my ($key,$value) = split(' = ');
    # Whitespace is also a PITA... try to remove forward/trailing
    $value =~ s/^\s+//;
    $value =~ s/\s+$//;
    $inv{$instanceid}{$key} = $value;
  }
}

# We care about:
# 1) What type of RAID card is installed/firmware
# 2) What logical volumes are present/status
# 3) What physical drives (type, size, make, model, serial, status)
#
## Disk.Bay.6:Enclosure.Internal.0-1:RAID.Integrated.1-1

# Build list of RAID controllers
my @PERC;
for my $node (keys %inv) {
  if ($node =~ /^RAID\.Integrated\.(\d{1,}-\d{1,})/) {
    # Found a RAID card, add to array
    push (@PERC,$inv{$node}{'FQDD'});
  }
}

sub PrintOutput {
  # Putting in subroutine so we can rip out later...
  for my $perc (@PERC) {
    say "$inv{$perc}{ProductName} ($perc)";
    say "|--FW Rev:\t\t$inv{$perc}{'ControllerFirmwareVersion'}";
    say "|--Primary Status:\t\t$inv{$perc}{'PrimaryStatus'}";
    say "|--Rollup Status:\t\t$inv{$perc}{'RollupStatus'}";
    say "|";
    # Now find any logical volumes for this controller
    # Disk.Virtual.0:RAID.Integrated.1-1
    for my $lv (grep { /Disk.Virtual.\d{1,}:$perc/ } keys %inv) {
      say "|--$inv{$lv}{'Name'}";
      say "|  |--RAID Type:\t\t$inv{$lv}{'RAIDTypes'}";
      say "|  |--RAID Status:\t\t$inv{$lv}{'RAIDStatus'}";
      say "|  |--Primary Status:\t\t$inv{$lv}{'PrimaryStatus'}";
      say "|  |--Rollup Status:\t\t$inv{$lv}{'RollupStatus'}";
      say "|  |--Media Type:\t\t$inv{$lv}{'MediaType'}";
      say "|  |--Disk Cache:\t\t$inv{$lv}{'DiskCachePolicy'}";
    }
    say "|";
    # Now find disks that belong to this controller
    # unfortunately there is no way to associate a disk to a logical volume
    # that I've found so far
    # Disk.Bay.7:Enclosure.Internal.0-1:RAID.Integrated.1-1
    for my $disk (grep { /Disk.Bay.\d{1,}:[^:](.+)$/} keys %inv) {
      $inv{$disk}{'SizeInBytes'} =~ m/^(\d+)/;
      my $size = Format::Human::Bytes::base2($1);
      say "|--$size $inv{$disk}{'Manufacturer'} $inv{$disk}{'MediaType'}";
      say "|  |--Type:\t\t$inv{$disk}{'MediaType'}";
      say "|  |--Protocol:\t\t$inv{$disk}{'BusProtocol'}";
      say "|  |--Model:\t\t$inv{$disk}{'Model'}";
      say "|  |--FW Rev:\t\t$inv{$disk}{'Revision'}";
      say "|  |--Serial:\t\t$inv{$disk}{'SerialNumber'}";
      say "|  |--Phy Slot:\t\t$inv{$disk}{'Slot'}";
      say "|  |--RAID Status:\t$inv{$disk}{'RaidStatus'}";
      say "|  |--Primary Status:\t$inv{$disk}{'PrimaryStatus'}";
      say "|  |--Rollup Status:\t$inv{$disk}{'RollupStatus'}";
      say "|  |--Remaining Endur.:\t$inv{$disk}{'RemainingRatedWriteEndurance'}";
      say "|";
    }
  }
}
&PrintOutput;

exit 0;


__END__

=head1 NAME

B<idrac_raid.pl> - Demo tool/wrapper around racadm to get quick raid/hdd status

=head1 SYNOPSIS

B<idrac_raid.pl> -u <username> -p <password> -h <hostname>

=head1 OPTIONS

=over 8

=item B<--pass|-p>

The password of the remote iDrac

=item B<--user|-u>

The user of the remote iDrac

=item B<--host|-h>

The remote hostname or IP of the idrac
