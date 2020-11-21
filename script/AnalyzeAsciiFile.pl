#!/usr/bin/perl -w
##############################################################################
#
# Program: AnalyzeAsciiFile.pl
#
# Description: This script will analyze a file assuming it is an ASCII file.
#              Any Characters above 127 will be noted as Extended Characters.
#              These are typlically extended or WE characters which technically
#              would mean the file is no longer an ASCII file and could be any
#              8 bit encoded Code Page like ISO8859-1 or Windows-1252.
#              There is no real way to know what the encoding is except for
#              knowing where the data came from.
#
# Notes: 
#     Breakdown of characters:
#            0 -  31, 127  ASCII Control  (Will display as ".")
#           32 - 126       ASCII
#          128 - 255       Extended       (Will display as ".")
#
# === Modification History ===================================================
# Date       Author           Comments
# ---------- --------------- -------------------------------------------------
# 02-27-2005 Steve Boyce     Created.
# 08-21-2007 Steve Boyce     Updated for better formatted report
# 08-15-2009 Steve Boyce     Added binary column
#                            Changed name of script and more accurately described
#                            what this script does.
#
##############################################################################

use strict;
use Getopt::Std;

#-- Declare all getopt vars
use vars qw(
            $opt_h
           );

my $NumberOfParameters         = scalar(@ARGV);
my $RecordsRead                = 0;
my $LengthOfInputLine          = 0;
my $CurColPos                  = 0;
my $InCharacter                = "";
my $DispCharacter              = "";
my $CharType                   = "";
my $AsciiCharCode              = 0;
my $HexCharCode                = "";
my $NumberOfASCIIControlChars  = 0;
my $NumberOfExtendedChars        = 0;
my $InputFile                  = "";

my $BeforeCharacters           = "";
my $BeforeCharactersMaxLength  = 20;
my $BeforeCharactersStart      = 0;
my $BeforeCharactersEnd        = 0;
my $BeforeCharactersLength     = 0;

my $AfterCharacters            = "";
my $AfterCharactersMaxLength   = 20;
my $AfterCharactersStart       = 0;
my $AfterCharactersLength      = 0;

##############################################################################
sub MinNum
{

   my ($Num1, $Num2) = @_;
   my $RetVal = $Num1;

   if ( $Num2 < $Num1 ) {
      $RetVal = $Num2;
   }

   return $RetVal
}

##############################################################################
sub MaxNum
{

   my ($Num1, $Num2) = @_;
   my $RetVal = $Num1;

   if ( $Num2 > $Num1 ) {
      $RetVal = $Num2;
   }

   return $RetVal
}

##############################################################################
#-- Main

getopts('h') or die "Type AnalyzeAsciiFile.pl -h for help\n";

#-- Make sure we have the required number of parms
($NumberOfParameters == 1) or die "Error: Wrong number of parameters.\nType AnalyzeAsciiFile.pl -h for help.\n";

if ( $opt_h ) {
print <<ENDOFHELP;

Syntax: AnalyzeAsciiFile.pl [options]
Description: This script will analyze an assumed ASCII file and report interesting statistics.
             The line feed character (10) is not reported on in any way by this process.
             It is assumed to terminate lines, as expected in ASCII text files.
Parameters : File to process.
Options    : -h - This help
             -c - Display control characters (00-31, 127)
             -r - Display NULL characters (00)
             -t - Display TAB characters (09)
             -r - Display Carriage Return Characters (10)

ENDOFHELP
exit;
}

$InputFile  = $ARGV[0];

open(fhInputHandle, "<".$InputFile) or die "Error: Unable to open: $InputFile\n";

print "Character Type      Line Column Dec Hex Binary   Char Context\n";
print "-------------- --------- ------ --- --- -------- ---- -------------------------------------------\n";
#--    14             9         6      5     3   8        4  varies
#--    ASCII Control  999999999 999999 999 99  11111111 X    XXXXXXXXXXXXXXXXXXXXX...XXXX
#--    Extended       999999999 999999 999 99  11111111 X    XXXXXXXXXXXXXXXXXXXXX...XXXX

while (<fhInputHandle>) {
   $RecordsRead++;
   chomp();

   #-- Traverse line and count extended charcaters
   $LengthOfInputLine = length($_);
   $CurColPos = 0;
   while ($CurColPos < $LengthOfInputLine) {

      $InCharacter = substr($_, $CurColPos, 1);
      $AsciiCharCode = ord($InCharacter);
      $HexCharCode = sprintf("%lx", $AsciiCharCode);

      if ($AsciiCharCode >= 128) {
         #-- Extended
         $NumberOfExtendedChars++;
         $DispCharacter = '.';
         $CharType = "Extended";
      }
      elsif ( ($AsciiCharCode >= 0 && $AsciiCharCode <= 31) || $AsciiCharCode == 127) {
            $NumberOfASCIIControlChars++;
            $DispCharacter = '.';
            $CharType = "ASCII Control";
      }
      else {
         $DispCharacter = $InCharacter;
         $CharType = "ASCII";
      }

      $BeforeCharacters = "";
      if ( $CurColPos > 0 ) {
         $BeforeCharactersStart  = MaxNum($CurColPos - $BeforeCharactersMaxLength, 0);
         $BeforeCharactersEnd    = MaxNum($CurColPos - 1, 0);
         $BeforeCharactersLength = ($BeforeCharactersEnd - $BeforeCharactersStart) + 1;
         $BeforeCharacters = substr($_, $BeforeCharactersStart, $BeforeCharactersLength);
         $BeforeCharacters =~ s/[\x00-\x1F|\x7F-\xFF]/\./g;
      }

      $AfterCharacters = "";
      if ( $CurColPos < ($LengthOfInputLine-1) ) {
         $AfterCharactersStart  = $CurColPos + 1;
         $AfterCharactersLength = MinNum($AfterCharactersMaxLength, ($LengthOfInputLine - $CurColPos) - 1);
         $AfterCharacters = substr($_, $AfterCharactersStart, $AfterCharactersLength);
         $AfterCharacters =~ s/[\x00-\x1F|\x7F-\xFF]/\./g;
      }

      if ( $CharType eq "ASCII Control" or $CharType eq "Extended" ) {
         printf("%-14s %9s %6s %3s %3s %08s [%-1s]  %-45s\n",
                 $CharType,
                 $RecordsRead,
                 $CurColPos+1,
                 $AsciiCharCode,
                 $HexCharCode,
                 sprintf("%b", $AsciiCharCode),
                 $DispCharacter,
                 $BeforeCharacters."[".$DispCharacter."]".$AfterCharacters
               );
      }

      $CurColPos++;
   }
}
print "Total Rows                      : $RecordsRead\n";
print "Total ASCII Control Characters  : $NumberOfASCIIControlChars\n";
print "Total Extended Characters       : $NumberOfExtendedChars\n";
