#!/usr/bin/perl -w

use strict;
use File::Copy;

#-- Debuffer output
$| = 1;

( scalar(@ARGV) == 1 ) or die "Error: missing parameter.  Expecting <input file name>\n";

my $OrigFile = $ARGV[0];
my $BackupFile = "$OrigFile.bak";
my $NewFile = "$OrigFile.new";

print "OrigFile: $OrigFile...\n";

( -e "$OrigFile" ) or die "Error: File does not exist: $OrigFile\n";

open(fhOrigFile, "<:utf8", "$OrigFile") or die "Error: unable to open: $OrigFile\n";

my @Row = ();
my $RowLength = 0;
my $MaxRowLength = 0;
my $MaxRow = 0;
my $ReadCount = 0;
my $WriteCount = 0;
my $nullchar = chr(0);
my $pid;
while ( <fhOrigFile> ) {
   $ReadCount++;
   $RowLength = length($_);
   if ( $RowLength > $MaxRowLength ) {
      ($pid) = split(/\|/, $_);
      $MaxRowLength = $RowLength;
      $MaxRow = $ReadCount;
      if ( "$pid" eq "101879782759211470" ) {
         print "PID: $pid - Longest row so far is $MaxRow with $MaxRowLength characters.\n";
         #$_ =~ s/$nullchar//g;
      }
   }
}

print "$ReadCount records read.\n";
print "Longest row is $MaxRow with $MaxRowLength characters.\n";
print "Done.\n";

close fhOrigFile;
