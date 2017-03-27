########################################################
# 
# Original Script by https://www.unixdaemon.net/commandline/mounted-disk-check/
# Modified by Nexpert AG for use with PRTG Network Monitor
#
#
# Description:    	
#
# This perl script compares the mounted devices of an linux server againts /etc/fstab.
# This script alarms if devices not mounted but should be mounted.
#					
# Example:			
#
# 1. Copy script to /var/prtg/scripts
# 2. make the file executable
# 3. In PRTG Create SSH Script and select this script
# 4. Test it! unmount & mount devices
#
#########################################################
#!/usr/bin/perl -w
use strict;
use warnings;

# doesn't pick up offline swap partitions

# deal with unexpected problems.
$SIG{__DIE__} = sub { print "@_"; exit 3; };

my $mount = '/bin/mount';
my $fstab = '/etc/fstab';
my (%mounted_disks, %fstab_disks); # store the read details.

########################################################
# get the device and mount point of the mounted disks
########################################################

open( my $mount_fh, "$mount |")
  || die "Failed to open $mount: $!";

while ( <$mount_fh> ) {
  next unless m!^/dev/!;
  my ($device, $mount_point) = (split(/\s+/, $_))[0,2];
  $mounted_disks{$mount_point} = $device;
}

close $mount_fh;

########################################################
# get the device and mount point from fstab (what should be mounted)
########################################################

open( my $fstab_fh, $fstab)
  || die "Failed to open $fstab: $!";

while ( <$fstab_fh> ) {
  next unless m!(^/dev/)|(^LABEL)!;
  my ($device, $mount_point) = (split(/\s+/, $_))[0,1];
  next unless $mount_point =~ m!/!; # drop swap partitions
  next if $device =~ m!(^/dev/cdrom)|(^/dev/fd\d+)!;

  # trim any marked with labels. We can't check the device on these = note in docs
  if ($device =~ s/^LABEL=//) {
    delete $mounted_disks{$device};
    next;
  }

  $fstab_disks{$mount_point} = $device;
}

close $fstab_fh;

########################################################
# find inconsistant disks
########################################################

my @not_mounted    = sort grep { ! exists $mounted_disks{$_} } keys %fstab_disks;
my @not_persistent = sort grep { ! exists $fstab_disks{$_}   } keys %mounted_disks;

########################################################
# Build output
########################################################

my $message = "0:0:All disks are mounted and persistent";
my $exit_code = 0;


$exit_code = 1                                   if (@not_mounted || @not_persistent);
$message  = "1:1: "                            if (@not_mounted || @not_persistent);
$message .= "@not_mounted not mounted"       if  @not_mounted;

print "$message\n";

