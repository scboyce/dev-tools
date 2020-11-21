#!/usr/bin/perl -w
 
# This perl script generates MD5 Checksums
 
use strict;
use IO::File;
use Getopt::Long;
use Digest::MD5;
 
my $File = $ARGV[0]; 
my $md5 = Digest::MD5->new;
my $check = 1;
 
open(FILE, $File) or die "Error: Could not open $File";
binmode(FILE);
my $md5sum = $md5->addfile(*FILE)->hexdigest; 
close FILE;
 
print "$md5sum\n";
