#!/usr/bin/perl
#
# Copyright (C) 2004-2007,2022 Hannes Loeffler
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2, or (at your option)
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
#
# convert Jim Breen's JMnedict to JIS X 4081 (EPWING subset) format
# needs FreePWING (http://www.sra.co.jp/people/m-kasahr/freepwing/)
#



use strict;
use PerlIO::gzip;
use Getopt::Long;		# actually already used by FreePWING
use FreePWING::FPWUtils::MarkupInterface qw(FreePWING_encode FreePWING_write);
use Jcode;
use Unicode::MapUTF8 qw(from_utf8);
use XML::Twig;
use Lingua::DE::ASCII qw(to_ascii);


my ($datafile, $inffile, $rdmfile, $cprfile, $gaijifile, $debug); # command line parameters
my ($icnt, $ecnt);		# counter
my (%kanji, %rev, %gaiji_table); # data storage
my %types = (			# type conversion table
	     "surname" => "s",
	     "place" => "pl",
	     "unclass" => "u",
	     "company" => "c",
	     "product" => "pr",
	     "masc" => "m",
	     "fem" => "f",
	     "person" => "p",
	     "given" => "g",
	     "station" => "st"
	    );



### parse command line
unless (GetOptions("data-file=s" => \$datafile,
		   "info-file=s" => \$inffile,
		   "readme-file=s" => \$rdmfile,
		   "copyright-file=s" => \$cprfile,
		   'gaiji-file=s' => \$gaijifile,
		   "debug=i" => \$debug) ) {
  exit 1;
}

# construct gaiji table
open GT, "< $gaijifile" || die "$0: failed to open the file, $!: $gaijifile\n";

while (<GT>) {
  my ($char, $name) = split;
  $gaiji_table{$char} = $name;
}

### initialize and write menu and copyright information
print "\n*** Creating JMnedict/EPWING\n\n";
print "*** writing menu and copyright information...\n";
write_menu();
write_copy();


### parse dictionary file and store data
print "*** processing data file $datafile...\n";

open DATA, "<:gzip", "$datafile" or
  die "$0: failed to open the file, $!: $datafile\n";

my $entry = new XML::Twig(twig_handlers => {"entry" => \&process_entry},
			  NoExpand => 1);
$entry->parse(\*DATA);
$entry->purge;

close DATA;


### write data
print "*** registering kanji(kana)->romaji entries...\n";
$ecnt = register(\%kanji, '; ');
print "*** $ecnt entries processed\n";
print "*** $icnt JIS X 0212 entries ignored\n";

print "*** registering romaji->kanji(kana) entries...\n";
$ecnt = register(\%rev, ' ');
print "*** $ecnt entries processed \n\n";
print "*** finished processing data file $datafile\n\n";


exit 0;
### end of main



###  subroutines

sub process_entry {
  my ($twig, $entry) = @_;

  my ($keb, $reb, $ent_seq);		# tags
  my ($key, $text);
  my (@name_type, @trans_det);


  # added for debugging
  $ent_seq = 0;

  if ($debug) {
    if (defined ($ent_seq = ($entry->descendants('ent_seq'))[0] ) ) {
      $ent_seq = $ent_seq->first_child->trimmed_text();
    }
  }

  # <k_ele>: kanji element
  # <keb>: processed directly because other elements of <k_ele> are (mostly)
  # unused
  if (defined ($keb = ($entry->descendants('keb'))[0] ) ) {
    $keb = $keb->first_child->trimmed_text();

    # ignore entries with JIS X 0212-1990 characters
    if (jcode($keb, 'utf8')->euc =~ m!\x8F[\xA1-\xFE][\xA1-\xFE]!) {
      $icnt++;
      $twig->purge;
      return;
    }
  }
  # </keb>
  # </k_ele>

  # <r_ele>: reading element
  # <reb>: processed directly because other elements of <r_ele> are not used
  if (defined ($reb = ($entry->descendants('reb'))[0] ) ) {
    $reb = $reb->first_child->trimmed_text();
  }
  # </reb>
  # </r_ele>

  # <trans>: translational equivalent of the Japanese name
  foreach my $t ($entry->descendants('trans') ) {
    foreach my $n ($t->descendants('name_type') ) {
      push @name_type, $n->first_child->trimmed_text();
    }

    foreach my $d ($t->descendants('trans_det') ) {
      $text = $d->first_child->trimmed_text();
      $text = from_utf8(-string => $text, -charset => 'latin1');
      push @trans_det, $text;
    }
  }
  # </trans>

  $twig->purge;

  # ...and end of XML data parsing


  # format entries
  if ($keb ne '') {
    $key = $keb;
  } else {
    $key = $reb;
  }

  for (my $i = 0; $i <= $#trans_det; $i++) {
    my ($romaji, $contents);


    $contents = $trans_det[$i];

    # remove entity markers and convert name type to short name
    if ($name_type[$i] ne '') {
      $name_type[$i] =~ s/(&|;)//g;

      foreach my $key (%types) {
	if ($name_type[$i] eq $key) {
	  $name_type[$i] = $types{$key};
	  last;
	}
      }

      $contents .= "($name_type[$i],";
    }

    $contents =~ s/,$/)/;

    # convert to gaiji if necessary: assume one-byte characters only
    $contents =~
      s!([\x80-\xFF])!<gaiji type=\"half\" name=\"$gaiji_table{$1}\">!g;

    $kanji{join("\x00", $key, $ent_seq)} .= "$contents, ";

    # do some basic cleanup in romaji keys
    $romaji = $trans_det[$i];
    $romaji =~ s!\s*\(.*?\)\s*!!g;
    $romaji =~ s!(.*?),!\1!;
    $romaji =~
      s!([\x80-\xFF])!<gaiji type=\"half\" name=\"$gaiji_table{$1}\">!g;
    $romaji = to_ascii($romaji);

    if (length($romaji) > 2 and length($romaji) < 50 and
	$romaji !~ m/[0-9_><"({;:=?+]/) {
      $rev{join("\x00", $romaji, $ent_seq)} .= "$key\x00";
    }
  }

  $kanji{join("\x00", $key, $ent_seq)} =~ s/, $/\x00/;
}


sub register {
  my ($hash, $sep) = @_;

  my $cnt;


  foreach my $keys (sort keys %$hash) {
    my (%dupl, $contents);
    my @split_key = split("\x00", $keys);
    my $key = $split_key[0];
    my $ent_seq = $split_key[1];

    # ignore duplicates
    foreach my $c (split '\x00', $$hash{$keys}) {
      if (!defined($dupl{$c}) ) {
        $dupl{$c} = 1;
      } else {
        next;
      }

      $contents .= "$c$sep";
    }

    $contents =~ s!$sep$!!;	# remove final separator

    $key = jcode($key, 'utf8')->euc;
    $contents = jcode($contents, 'utf8')->euc;

    print STDERR "Registering [$ent_seq] $key : $contents\n" if $debug;

    $cnt++;
    FreePWING_write("<entry><heading>$key</heading><key name=\"$key\">" .
		    "<keyword>$key</keyword><nl>".
		    "<indent level=\"2\">$contents<nl>");
  }

  return $cnt;
}


sub write_menu {

  my $l = 0;


  FreePWING_write("<menu>" .
                  "<ref target=\"M1\">README</ref><nl>" .
                  "<ref target=\"M2\">Dictionary Information</ref><nl>");

  foreach my $file ($rdmfile, $inffile) {
    my $contents;


    open IN, "< $file" or die "$0: failed to open $file\n";

    $l++;

    while (<IN>) {
      chomp;
      $contents .= FreePWING_encode($_) . '<nl>';
    }

    close(IN);

    FreePWING_write("<menu><tag name=\"M$l\">$contents");
  }
}


sub write_copy {

  my $contents;


  open IN, "< $cprfile" or die "$0: failed to open $cprfile\n";

  while (<IN>) {
    chomp;
    $contents .= $_ . '<nl>';
  }

  close IN;

  FreePWING_write("<copyright>$contents");
}
