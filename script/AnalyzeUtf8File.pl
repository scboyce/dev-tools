#!/usr/bin/perl -w
##############################################################################
#
# Program: AnalyzeUtf8File.pl
#
# Description: This script will analyze a UTF-8 file and report some interesting stats.
#              It wll read the file as a UFT-8 file and therefore assumes it's a valid UTF-8 file.
#
#              The output of this script is best viewed when locale is set to en_US.UTF-8
#
# UTF-8 in a Nutshell (by Steve Boyce 8/16/2009):
#
#     UTF-8 is one method of many that "encodes" Unicode characters in multi-byte sequences.
#     This means that the sequences of bytes that you find in the file are not the characters
#     themselves, they are the encoded version of the characters.
#     The encoding scheme is layed out below.
#     The 1's and 0' are the encoding control bits and
#     The x's are the encoded Unicode character.
#
#     Breakdown of UTF-8 Byte Distribution
#                                             Number of     Value Range
#     1st Byte  2nd Byte  3rd Byte  4th Byte  Free Bits     of 1st Byte (dec)
#     --------  --------  --------  --------  ------------  -----------------
#     0xxxxxxx                                           7    0 -> 127
#     110xxxxx  10xxxxxx                      5+6     = 11  193 -> 223
#     1110xxxx  10xxxxxx  10xxxxxx            4+6+6   = 16  224 -> 239
#     11110xxx  10xxxxxx  10xxxxxx  10xxxxxx  3+6+6+6 = 21  240 -> 247
#
#     Value Range of continuing byte in multi-byte sequence: 129 -> 191
#
#     Depending on the UTF-8 version, more bytes are possible, but this pattern is maintainted.
#
#     For example, here is how the UTF-8 BOM character is encoded.
#        The physical UTF-8 BOM Sequence is three bytes long:
#           Hex value is: EF BB BF
#           Dec value is: 15711167
#           Bin value is: 11101111 10111011 10111111
#                             ----   ------   ------
#        Using the chart above, the Unicode bits have been underlined.
#
#        If you assemble them like this: 1111 1110 1111 1111, you can now determine the character.
#                                        F    E    F    F
#        FEFF is the Actual UTF-8 Unicode character, not to be confused with the physical encoded byte sequence.
#
#        http://www.fileformat.info/info/unicode/char/feff/index.htm
#        http://en.wikipedia.org/wiki/Byte_Order_Mark
#
#        Only one BOM character is allowed and it must be the first character at the beginning of the file.
#        
#     If you were to examin a UTF-8 file one byte at a time ignoring any encoding, the following things would be true:
#        - All bytes with a Decimal value < 128 are both ASCII and UTF-8 single byte characters.  Cool!
#        - All bytes with a Decimal value > 127 must be in the following range:
#          129 -> 191, or 193 -> 223, or 224 to 239, or 240 to 247
#          Any bytes outside these ranges are considered invalid bytes in a UTF-8 File
#        - When a byte matches the pattern: 110xxxxx there must be only one byte after it like 10xxxxxx
#        - When a byte matches the pattern: 1110xxxx there must be only two bytes after it like 10xxxxxx
#        - When a byte matches the pattern: 11110xxx there must be only three bytes after it like 10xxxxxx
#          Note that the BOM character is a valid three byte encoded UTF-8 character.
#
# === Modification History ===================================================
# Date       Author           Comments
# ---------- --------------- -------------------------------------------------
# 02-20-2012 Steve Boyce     Created.
# 05-03-2012 Steve Boyce     Added counts of UTF-8 characters by number of bytes
#
##############################################################################

use strict;
use File::Basename;
use Getopt::Std;
use encoding 'utf8';

use constant TRUE => 1;
use constant FALSE => 0;

#-- Declare all getopt vars
use vars qw(
            $opt_h
            $opt_c
            $opt_t
            $opt_u
            $opt_p
           );

#-- Declare all progam vars
my $NumberOfParameters         = 0;
my $RecordsRead                = 0;
my $LengthOfInputLine          = 0;
my $CurColPos                  = 0;
my $InCharacter                = "";
my $DecimalCharCode            = 0;
my $HexCharCode                = "";
my $NumberOfAsciiCtrlChars     = 0;
my $NumberOfUtf8BomChars       = 0;
my $NumberOfUtf8Chars          = 0;
my $UtfBomCharLineNumber       = 0;
my $UtfBomCharColNumber        = 0;

my $NumberOf6ByteChars         = 0;
my $NumberOf5ByteChars         = 0;
my $NumberOf4ByteChars         = 0;
my $NumberOf3ByteChars         = 0;
my $NumberOf2ByteChars         = 0;

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

my $DisplayThisOne             = FALSE;

my $OSRetVal = 0;

##############################################################################
sub ShowBlurb
{
print <<ENDOFBLURB;

Syntax: AnalyzeUtf8File.pl [options] <FileName>

Description: Analyze a presumed UTF-8 file and report interesting stats about it.

Parameters: FileName - Fully qualified name of file to examine.

Options:   -h - This help
           -c - Display Control Characters (0x00 -> 0x1f)
           -t - Display Control Characters (0x00 -> 0x1f excluding TABs and Carriage Returns)
           -u - Display UTF-8 Characters (0xc1 -> and up)
           -p<CodePoint> - Display Specific UTF-8 Character
                           CodePoints are Hexidecimal
                           For example: the lowercase letter a is 0x61
                              -p0 is NULL
                              -p9 is TAB
                              -pd is Carriage Return
                              -p61 is LowerCase A
                              -p20ac is the Euro Currency Symbol
                              -pa3 is the Pound Sterling

Notes: Record terminators (LF for Unix and CR/LF for DOS) will be excluded from analysis.
       Only use one option at a time.

ExitCodes: 0 - Success
           1 - Failure

ENDOFBLURB
}

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
sub StripASCIIControlChars
{
   my ($InStr) = @_;
   my $RetVal = "";
   my $LengthOfInputStr = length($InStr);
   my $CurPos = 0;
   my $InCharacter;
   my $DecimalCharCode;
   
   while ($CurPos < $LengthOfInputStr) {

      $InCharacter = substr($InStr, $CurPos, 1);
      $DecimalCharCode = ord($InCharacter);
      if ( ($DecimalCharCode <= 31) || $DecimalCharCode == 127  || $DecimalCharCode == 65279) {
         $RetVal = $RetVal . ".";
      }
      else {
         $RetVal = $RetVal . $InCharacter;
      }
      $CurPos++;
   }

   return $RetVal
}


##############################################################################
sub DisplayLine
{
   my ($Type, $Line) = @_;

   $BeforeCharacters = "";
   if ( $CurColPos > 0 ) {
      $BeforeCharactersStart  = MaxNum($CurColPos - $BeforeCharactersMaxLength, 0);
      $BeforeCharactersEnd    = MaxNum($CurColPos - 1, 0);
      $BeforeCharactersLength = ($BeforeCharactersEnd - $BeforeCharactersStart) + 1;
      $BeforeCharacters = StripASCIIControlChars(substr($Line, $BeforeCharactersStart, $BeforeCharactersLength));
   }

   $AfterCharacters = "";
   if ( $CurColPos < ($LengthOfInputLine-1) ) {
      $AfterCharactersStart  = $CurColPos + 1;
      $AfterCharactersLength = MinNum($AfterCharactersMaxLength, ($LengthOfInputLine - $CurColPos) - 1);
      $AfterCharacters = StripASCIIControlChars(substr($Line, $AfterCharactersStart, $AfterCharactersLength));
   }

   if ( $Type eq "ASCII Control" || $Type eq "UTF-8 BOM" ) {
      print sprintf("%-14s", $Type), "  ",
            sprintf("%9s",   $RecordsRead), "  ",
            sprintf("%6s",   $CurColPos+1), "  ",
            sprintf("%10s",  $DecimalCharCode), "  ",
            sprintf("%8s",   $HexCharCode), "  ",
            sprintf("%-4s",  "."), "  ",
            sprintf("%1s",   $BeforeCharacters."[.]".$AfterCharacters),
            "\n";
   }
   else {
      print sprintf("%-14s", $Type), "  ",
            sprintf("%9s",   $RecordsRead), "  ",
            sprintf("%6s",   $CurColPos+1), "  ",
            sprintf("%10s",  $DecimalCharCode), "  ",
            sprintf("%8s",   $HexCharCode), "  ",
            sprintf("%-4s",  $InCharacter), "  ",
            sprintf("%1s",   $BeforeCharacters."[".$InCharacter."]".$AfterCharacters),
            "\n";
   }
}

##############################################################################
sub AnalyzeFile
{

   my $Retval = TRUE;

   if (open fhInputHandle, "<:utf8", $InputFile) {

      print "\n";
      print "Unprintable ASCII Control characters will appear as periods [.]\n";
      print "Unprintable UTF-8 characters will appear as question marks [?]\n";
      print "All column number references are logical character positions.  Some my actually be multi-byte.\n\n";

      print "                                    Unicode Code Point\n";
      print "                                   --------------------\n";
      print "Character Type       Line  Column     Decimal       Hex  Char  Context\n";
      print "--------------  ---------  ------  ----------  --------  ----  ---------------------------------\n";
      #--    14              9          6       10          8         4     varies
      #--    ASCII Control   999999999  999999  9999999999  99999999  X     XXXXXXXXXXXXXXXXX...XXXX
      #--    UTF-8           999999999  999999  9999999999  99999999  X     XXXXXXXXXXXXXXXXX...XXXX
      #--    UTF-8 BOM       999999999  999999  9999999999  99999999  X     XXXXXXXXXXXXXXXXX...XXXX

      while (<fhInputHandle>) {
         $RecordsRead++;
         #print "Lines Processed: $RecordsRead\n" if ( $RecordsRead % 1000 == 0 );
         #-- Chomp records delimiter
         chomp;

         #-- Traverse line and gather stats
         $LengthOfInputLine = length($_);
         $CurColPos = 0;
         while ($CurColPos < $LengthOfInputLine) {

            $InCharacter = substr($_, $CurColPos, 1);
            $DecimalCharCode = ord($InCharacter);
            $HexCharCode = sprintf("%x", $DecimalCharCode);

            if ( $opt_c ) {
               #-- Display Control Characters - (All)
               if ( $DecimalCharCode <= 31 || $DecimalCharCode == 127 ) {
                  $NumberOfAsciiCtrlChars++;
                  DisplayLine("ASCII Control", $_);
               }
            }
            elsif ( $opt_t ) {
               #-- Display Control Characters excluding TABs and Carriage Returns
               if ( $DecimalCharCode <= 31 || $DecimalCharCode == 127 ) {
                  if ( !($DecimalCharCode == 9 || $DecimalCharCode == 13) ) {
                     $NumberOfAsciiCtrlChars++;
                     DisplayLine("ASCII Control", $_);
                  }
               }
            }
            elsif ( $opt_u ) {
               #-- Display UTF-8 Characters
               if ($DecimalCharCode >= 128) {
                  $NumberOfUtf8Chars++;
                  #-- Possible UTF-8 character
                  if ($DecimalCharCode == 65279) {
                     #-- UTF-8 BOM
                     $NumberOfUtf8BomChars++;
                     if ( $NumberOfUtf8BomChars == 1 ) {
                        #-- Remember the line number only for the first one
                        $UtfBomCharLineNumber = $RecordsRead;
                        $UtfBomCharColNumber  = $CurColPos+1;
                     }
                     DisplayLine("UTF-8 BOM", $_);
                  }
                  else {
                     #-- UTF-8
                     #-- Determine number of bytes
                     if ( $DecimalCharCode > 67108863 ) {
                        #-- 6 Byte
                        $NumberOf6ByteChars++;
                     }
                     else {
                        if ( $DecimalCharCode > 2097151 ) {
                           #-- 5 Byte
                           $NumberOf5ByteChars++;
                        }
                        else {
                           if ( $DecimalCharCode > 65535 ) {
                              #-- 4 Byte
                              $NumberOf4ByteChars++;
                           }
                           else {
                              if ( $DecimalCharCode > 2047 ) {
                                 #-- 3 Byte
                                 $NumberOf3ByteChars++;
                              }
                              else {
                                 #-- 2 Byte
                                 $NumberOf2ByteChars++;
                              }
                           }
                        }
                     }
                     DisplayLine("UTF-8", $_);
                  }
               }
            }
            elsif ( $opt_p ) {
               #-- Display specific UTF-8 Characters
               if ( "$HexCharCode" eq "$opt_p" ) {
                  if ($DecimalCharCode >= 128) {
                     $NumberOfUtf8Chars++;
                     if ($DecimalCharCode == 65279) {
                        #-- UTF-8 BOM
                        $NumberOfUtf8BomChars++;
                        if ( $NumberOfUtf8BomChars == 1 ) {
                           #-- Remember the line number only for the first one
                           $UtfBomCharLineNumber = $RecordsRead;
                           $UtfBomCharColNumber  = $CurColPos+1;
                        }
                        DisplayLine("UTF-8 BOM", $_);
                     }
                     else {
                        #-- UTF-8
                        DisplayLine("UTF-8", $_);
                     }
                  }
                  else {
                     if ( $DecimalCharCode <= 31 || $DecimalCharCode == 127 ) {
                        $NumberOfAsciiCtrlChars++;
                        DisplayLine("ASCII Control", $_);
                     }
                     else {
                        DisplayLine("ASCII", $_);
                     }
                  }
               }
            }
            else {
               #-- Default - no options
               #-- Display Control Characters and UTF-8 Characters
               if ($DecimalCharCode >= 128) {
                  $NumberOfUtf8Chars++;
                  if ($DecimalCharCode == 65279) {
                     #-- UTF-8 BOM
                     $NumberOfUtf8BomChars++;
                     if ( $NumberOfUtf8BomChars == 1 ) {
                        #-- Remember the line number only for the first one
                        $UtfBomCharLineNumber = $RecordsRead;
                        $UtfBomCharColNumber  = $CurColPos+1;
                     }
                     #DisplayLine("UTF-8 BOM", $_);
                  }
                  else {
                     #-- UTF-8
                     #-- Determine number of bytes
                     if ( $DecimalCharCode > 67108863 ) {
                        #-- 6 Byte
                        $NumberOf6ByteChars++;
                     }
                     else {
                        if ( $DecimalCharCode > 2097151 ) {
                           #-- 5 Byte
                           $NumberOf5ByteChars++;
                        }
                        else {
                           if ( $DecimalCharCode > 65535 ) {
                              #-- 4 Byte
                              $NumberOf4ByteChars++;
                           }
                           else {
                              if ( $DecimalCharCode > 2047 ) {
                                 #-- 3 Byte
                                 $NumberOf3ByteChars++;
                              }
                              else {
                                 #-- 2 Byte
                                 $NumberOf2ByteChars++;
                              }
                           }
                        }
                     }
                     #DisplayLine("UTF-8", $_);
                  }
               }
               else {
                  if ( $DecimalCharCode <= 31 || $DecimalCharCode == 127 ) {
                     $NumberOfAsciiCtrlChars++;
                     #DisplayLine("ASCII Control", $_);
                  }
               }
            }

            #-- Next character
            $CurColPos++;
         }
      }
      print "\n";
      print "Total Rows                    : ", sprintf("%15s", $RecordsRead), "\n";
      if ( $opt_c || $opt_t || $opt_u || $opt_p ) {
         if ( $opt_c || $opt_t ) {
            print "Total ASCII Control Characters: ", sprintf("%15s", $NumberOfAsciiCtrlChars), "\n";
         }
         if ( $opt_u ) {
            print "Total UTF-8 BOM Characters    : ", sprintf("%15s", $NumberOfUtf8BomChars), "\n";
            print "Total UTF-8 Characters        : ", sprintf("%15s", $NumberOfUtf8Chars), "\n";
            print "Total 6 Byte UTF-8 Characters : ", sprintf("%15s", $NumberOf6ByteChars), "\n";
            print "Total 5 Byte UTF-8 Characters : ", sprintf("%15s", $NumberOf5ByteChars), "\n";
            print "Total 4 Byte UTF-8 Characters : ", sprintf("%15s", $NumberOf4ByteChars), "\n";
            print "Total 3 Byte UTF-8 Characters : ", sprintf("%15s", $NumberOf3ByteChars), "\n";
            print "Total 2 Byte UTF-8 Characters : ", sprintf("%15s", $NumberOf2ByteChars), "\n";
         }
         if ( $opt_p ) {
            print "Total UTF-8 Characters        : ", sprintf("%15s", $NumberOfUtf8Chars), "\n";
         }
      }
      else {
         print "Total ASCII Control Characters: ", sprintf("%15s", $NumberOfAsciiCtrlChars), "\n";
         print "Total UTF-8 BOM Characters    : ", sprintf("%15s", $NumberOfUtf8BomChars), "\n";
         print "Total UTF-8 Characters        : ", sprintf("%15s", $NumberOfUtf8Chars), "\n";
         print "Total 6 Byte UTF-8 Characters : ", sprintf("%15s", $NumberOf6ByteChars), "\n";
         print "Total 5 Byte UTF-8 Characters : ", sprintf("%15s", $NumberOf5ByteChars), "\n";
         print "Total 4 Byte UTF-8 Characters : ", sprintf("%15s", $NumberOf4ByteChars), "\n";
         print "Total 3 Byte UTF-8 Characters : ", sprintf("%15s", $NumberOf3ByteChars), "\n";
         print "Total 2 Byte UTF-8 Characters : ", sprintf("%15s", $NumberOf2ByteChars), "\n";
      }
      print "\n";

      if ( $NumberOfUtf8BomChars > 1 ) {
         print "WARNING: There should only ever be one BOM character in a Unicode file.\n"
      }
      if ( $NumberOfUtf8BomChars == 1 && !( $UtfBomCharLineNumber == 1 && $UtfBomCharColNumber == 1 )) {
         print "WARNING: The BOM character must be the first character in the first line\n";
      }
      
   }
   else {
      print STDERR "Error: can't open input file: $InputFile\n";
      $Retval = FALSE;
   }
   return $Retval;
}

##############################################################################
#-- Main    

if ( getopts('hctup:') ) {
   #-- See if we need help
   if ( ! $opt_h ) {
      #-- No help needed
      #-- Make sure we have the required number of parms
      $NumberOfParameters = scalar(@ARGV);
      if ($NumberOfParameters == 1) {
         $InputFile  = $ARGV[0];
         print "Analyzing: $InputFile\n";
         print "Looking for ASCII Control Characters...\n" if $opt_c;
         print "Looking for ASCII Control Characters (excluding TABs and CRs)...\n" if $opt_t;
         print "Looking for UTF-8 Characters...\n" if $opt_u;
         print "Looking for UTF-8 Character: (0x$opt_p)...\n" if $opt_p;
         print "Looking for ASCII Control and UTF-8 Characters...\n" if !($opt_c || $opt_t || $opt_u || $opt_p);
         if ( AnalyzeFile() ) {
            print "Done.\n";
         }
         else {
            $OSRetVal = 1;
         }
      }
      else {
         print STDERR "Error: Wrong number of parameters.\n";
         $OSRetVal = 1;
      }
   }
   else {
      ShowBlurb();
      $OSRetVal = 2;
   }
}
else  {
   #-- Problem with options (getops error)
   $OSRetVal = 1;
}
exit $OSRetVal;
