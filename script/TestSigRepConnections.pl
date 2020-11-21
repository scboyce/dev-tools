#!/usr/bin/perl -w

use DBI;
use Net::FTP;
use lib "/shared/inform/script/common";
use DbConnect;
use strict;

my $YamlConnection_OdsDw = `grep '^YamlConnection_OdsDw=' /shared/inform/param/Signature_Report.cfg | cut -d= -f2 | tr -d "\n"`;

my $yamlh=DbConnect->new;
$yamlh->getData($YamlConnection_OdsDw);
my $OraConnectString = $yamlh->{dbstring};
my $OraUserId = $yamlh->{username};
my $OraPassword = $yamlh->{password};

print "OraConnectString: $OraConnectString\n";
print "OraUserId: $OraUserId\n";

my $dbh = DBI->connect("$OraConnectString", "$OraUserId", "$OraPassword") or die 'died: $DBI::error';

my $query="select p.sid, s.ste_site_name, p.psr_username, p.psr_ftp_server, p.psr_password, p.psr_target_folder
             from ods.publ_signature_reports p
             join dw.dim_site s
               on sid = sid_key
            where psr_ocurrent = 'Y'
              and psr_enablement_status = 'E'";

my $sth=$dbh->prepare($query);
print "Gathering list of publishers to test...\n";
if (!$sth->execute) {
   die("died: " . $dbh->errstr . "\n");
}

my @Pubs;
my @PubRow;
while (@PubRow = $sth->fetchrow_array) {
   push @Pubs, [@PubRow];
}
$sth->finish;
$dbh->disconnect;

my $Sid = "";
my $PubName = "";
my $FtpUser = "";
my $FtpServer = "";
my $FtpPassword = "";
my $FtpRemoteDir = "";

my $ftp;

if ( scalar(@Pubs) ) {
   for my $x (0 .. $#Pubs) {
      $Sid = $Pubs[$x][0];
      $PubName = $Pubs[$x][1];
      $FtpUser = $Pubs[$x][2];
      $FtpServer = $Pubs[$x][3];
      $FtpPassword = $Pubs[$x][4];
      $FtpRemoteDir = $Pubs[$x][5];

      print "---------------------------------------------------------------------\n";
      print "SID       : $Sid\n";
      print "Publisher : $PubName\n";
      print "FTP User  : $FtpUser\n";
      print "FTP Server: $FtpServer\n";
      print "Remote Dir: $FtpRemoteDir\n";

      #-- Attempt to connect to Publisher site 
      $ftp = Net::FTP->new($FtpServer, Debug => 0);
      if ( $ftp ) {
         #-- Connected
         if ( $ftp->login($FtpUser,$FtpPassword) ) {
            #-- Logged in
            if ( $ftp->cwd($FtpRemoteDir) ) {
               #-- Changedir succeeded
               $ftp->quit;
               print "FTP Status: OK\n\n";
            }
            else {
               print "Error: Unable to change working directory to: $FtpRemoteDir\n";
               print "Error Message: ", $ftp->message, "\n";
            }
         }
         else {
            print "Error: Unable to login as: $FtpUser\n";
            print "Error Message: ", $ftp->message, "\n";
         }
      }
      else {
         print "Error: Unable to connect to: $FtpServer\n";
      }
   }
}
else {
   print "No enabled publishers.\n";
}
