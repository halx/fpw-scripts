#!/usr/bin/perl
#
# Copyright (C) 2004-2011 Hannes Loeffler
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
# convert example sentences by Prof. Y. Tanaka to EPWING format
# needs FreePWING (http://www.sra.co.jp/people/m-kasahr/freepwing/)
#



use strict;
use PerlIO::gzip;
use Getopt::Long;               # actually already used by FreePWING
use FreePWING::FPWUtils::MarkupInterface qw(FreePWING_encode FreePWING_write);
use Text::Kakasi;


my ($datadir, $rdmfile, $contents);
my ($A, $B, $japanese, $english, $kakasi, $kana);
my ($datafile, $rdmfile) = ("data/examples.gz", "data/README");
my ($prune, $debug) =  (1, 0);
my (%examples, %sentences);
my $JISX021n = qr/\x8F[\xA1-\xFE][\xA1-\xFE]/;


# parse command line
unless (GetOptions("data-file=s" => \$datafile,
		   "readme-file=s" => \$rdmfile,
                   "prune=i" => \$prune,
                   "debug=i" => \$debug) ) {
  exit 1;
}


### kanji/kana conversion
$kakasi = Text::Kakasi->new('-JH', '-c', '-o euc');

### write menu entry
print "\n*** Creating menu entry from \"$rdmfile\"...\n";

FreePWING_write("<menu>");

open RM, "< $rdmfile" or die "$0: failed to open $rdmfile\n";

while (<RM>) {
  my $contents = $_;
  $contents = FreePWING_encode($contents);
  FreePWING_write("$contents<nl>");
}

close RM;


### parse dictionary
print "*** Processing \"$datafile\"...\n";

# datafile is already in EUC-JP
open DF, "<:gzip", "$datafile" or die "$0: failed to open $datafile\n";

ENTRY: while ($A = <DF> and $B = <DF> ) {
  my %B_keys;

  if ($A =~ $JISX021n or $B =~ $JISX021n) {
    print STDERR "W> non JIS X 0208 character found!\n";
    next;
  }

  next if $A =~ /^\s*#/;
  next if $B =~ /^\s*#/;

  chomp ($A);
  chomp ($B);

  # remove IDs
  $A =~ s/#ID=.*?$//;

  # extract Japanese and English sentences
  $A =~ s/^A:\s+//;

  if ($A =~ m/(.*?)\s+(.*)\s*/) {
    $japanese = $1;
    $english = $2;
  }

  # eliminate obvious duplicates, keep first sentence
  if ($prune) {
    $kana = $kakasi->get($japanese);

    if (!defined($sentences{$kana}) ) {
      $sentences{$kana} = 1;
    } else {
      next ENTRY;
    }

    if (!defined($sentences{$english}) ) {
      $sentences{$english} = 1;
    } else {
      next ENTRY;
    }
  }

  # extract kanji keys
  $B =~ s/^B:\s+//;
  $B =~ s!\(\[|\]\)!!g;		# remove brackets
  $B =~ s!\{.*?\}~?!!g;		# remove forms of appearances

 GETK: foreach my $key (split ' ', $B) {
    next if $key =~ /[\x00-\x7F]/ and not $key =~ /[0-9)(]/;

    # consider only unique keys
    if (!defined($B_keys{$key}) ) {
      $B_keys{$key} = 1;
    } else {
      next GETK;
    }

    if ($key =~ m/\((.*?)\)/ ) {
      $kana = $1;
    } else {
      $kana = $kakasi->get($key);
    }

    $examples{"$key $kana"} .= "$japanese<$english\x00";
  }
}

undef %sentences;

### perform indexing
print "*** Indexing...\n";

foreach my $key (sort keys %examples) {
  my ($kanji, $kana) = split ' ', $key;

  my ($number, $entry);
  my $heading = "";


  $number = $1 if $kanji =~ m!\[(\d)\]!;
  $kanji =~ s!\[\d\]!!;
  $kana =~ s!\[\d\]!!;

  $heading .= "<super>$1</super>" if $number ne "";
  $heading .= " [$1]" if $kanji =~ m!\((.*?)\)!;
  $kanji =~ s!\(.*?\)!!;

  $entry = "<entry><heading>$kanji$heading</heading>";
  $entry .= "<key name=\"$kanji\">";
  $entry .= "<key name=\"$kana\">" if $kanji ne $kana;
  $entry .= "<keyword>$kanji";
  $entry .= "<super>$number</super>" if $number ne "";
  $entry .= " [$kana]" if $kanji ne $kana;
  $entry .= "</keyword><nl><indent level=\"2\">";

  foreach my $pair (split '\x00', $examples{$key}) {
    ($japanese, $english) = split "<", $pair;

    print "$key:\n$japanese\n$english\n" if $debug == 1;

    $entry .= "$japanese<nl><i>$english</i><nl>";
  }

  FreePWING_write($entry);
}

close(DF);

exit 0;
