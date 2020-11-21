#!/usr/bin/perl -w
##############################################################################
#
# Program: CleanParam.pl
#
# Description: Clean Informatica parameter file
#
# Notes: With no options it will just report on duplciate sections.
#
#        Type CleanParam.pl -h for help.
#
# === Modification History ===================================================
# Date       Author          Comments
# ---------- --------------- -------------------------------------------------
# 2014-09-08 Steve Boyce     Created.
#
##############################################################################

use strict;
use File::Copy;
use File::Basename;
use Getopt::Std;

use vars qw(
            $opt_h
            $opt_f
           );

#-- Debuffer output
$| = 1;

if ( getopts('hf') ) {

   if ( $opt_h ) {
      print "Syntax: CleanParam.pl [fh] parameter_file\n";
      print "Where: -f = Fix parameter file by deleting duplicate sections.\n";
      print "       -h = This help.\n";
      print "       parameter_file is an Informatica formatted parameter file.\n";
      print "A bak file will be created when using -f option and there is at least\n";
      print "one duplicate section.\n";
      exit 1;
   }
   if ( $opt_f ) {
      print "Removing Duplicates if any found...\n";
   }

   ( scalar(@ARGV) == 1 ) or die "Error: missing parameter.  Expecting <input file name>\n";

   my $ParameterFile = $ARGV[0];
   print "ParameterFile: $ParameterFile\n";

   ( -e "$ParameterFile" ) or die "Error: File does not exist: $ParameterFile\n";

   open(fhParameterFile, "<", "$ParameterFile") or die "Error: unable to open: $ParameterFile\n";

   my $BaseFilename = basename($ParameterFile);
   my $Pid=getppid();
   my $NewParameterFile = "/tmp/$BaseFilename"."."."$Pid";

   if ( $opt_f ) {
      open(fhNewParameterFile, ">", "$NewParameterFile") or die "Error: unable to open: $NewParameterFile\n";
   }

   my $SectionReadCount = 0;
   my $DupSectionCount = 0;
   my %SectionName = ();
   my $Skip = 0;
   while ( <fhParameterFile> ) {
      chomp;

      #-- Trim trailing spaces
      $_ =~ s/[ \t]*$//g;

      if ( m/^\[.*\]$/ ) {
         #-- This is a section line
         if ( $SectionName{$_} ) {
            #-- This section is aleady in the list
            print "$_ - Duplicate!\n";
            $DupSectionCount ++;
            $Skip = 1;
         }
         else {
            print "$_\n";
            $SectionName{$_} = 1;
            $Skip = 0;
         }
      }
      if ( ! $Skip ) {
         if ( $opt_f ) {
            print fhNewParameterFile "$_\n";
         }
      }
   }
   print "$DupSectionCount duplicate sections.\n";

   close fhParameterFile;
   if ( $opt_f ) {
      close fhNewParameterFile;
      if ( $DupSectionCount ) {
         print "Fixing parameter file...\n";
         copy($ParameterFile, "$ParameterFile.bak") or die "Backup failed: $!";
         move($NewParameterFile, $ParameterFile) or die "Move failed: $!";
         print "Done.\n";
      }
      else {
         unlink $NewParameterFile;
      }
   }
}
else {
   #-- Problem with options
   print "Boom!\n";
}
