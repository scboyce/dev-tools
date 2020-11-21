#!/usr/bin/perl -w

use strict;

use XML::Writer;
use IO::File;

my $output = new IO::File(">output.xml");

my $writer = new XML::Writer(OUTPUT => $output,
                             DATA_MODE => 1,
                             DATA_INDENT => 1,
                             ENCODING => 'utf-8'
                            );

$writer->xmlDecl("UTF-8");
$writer->comment("Sample XML file generatd by Perl w/XML::Writer CPAN Module");

$writer->startTag("employees");

   $writer->startTag("employee");
      $writer->startTag("eid");
         $writer->characters("1234");
      $writer->endTag("eid");
      $writer->startTag("ename");
         $writer->characters("Steve Boyce");
      $writer->endTag("ename");
   $writer->endTag("employee");

   $writer->startTag("employee");
      $writer->startTag("eid");
         $writer->characters("5678");
      $writer->endTag("eid");
      $writer->startTag("ename");
         $writer->characters("Steve Mon");
      $writer->endTag("ename");
   $writer->endTag("employee");

$writer->endTag("employees");

$writer->end();
$output->close();
