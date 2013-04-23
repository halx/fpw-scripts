#!/usr/bin/perl
#
# Copyright (C) 2004-2005 Hannes Loeffler
# based on code by Kazuhiko Shiozaki <kazuhiko@ring.gr.jp>
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
# convert EDICT formatted kanjidic to JIS X 4081 format (EPWING subset)
# needs FreePWING (http://www.sra.co.jp/people/m-kasahr/freepwing/)
#



use strict;
use PerlIO::gzip;
use Getopt::Long;               # actually already used by FreePWING
use FreePWING::FPWUtils::MarkupInterface qw(FreePWING_encode FreePWING_write);
use Jcode;
use Unicode::MapUTF8 qw(from_utf8);
use Lingua::DE::ASCII;		# import to_ascii

use subs qw(register_kanji register write_menu write_copy stroke_sort);


my ($lang, $datafile, $inffile, $rdmfile, $cprfile);
my ($radfile, $cradfile, $gaijifile);
my ($gaiji, $addCK, $printcodes, $printrads) = "1", "1", "1", "1";
my ($keycodes, $keyrads, $largebmp, $debug) = "1", "1", "1", "0";
my ($kanji, $radical, $stroke_cnt, $encoding);

my (@cradlist, @strcnt2radical, @strcnt2class_radical, @forward);

my (%reverse, %meaning);		# reverse and meaning index
my (%kanji_xrefs, %kanji2tag, %tag2kanji); # cross references
my (%class_radical2strcnt, %kanji2strcnt);
my (%gaiji_table, %kanji2radical, %class_radical2kanji, %cradcheck);

my $non_unique_codes = qr/^([BCGPS]|DR)/;
my $xref_codes = qr/J[01]|DR|N|I/;	# "H" and "O" are outside JIS208
my $xref_mark_types = qr/DR|N|I/; # cross references that will be marked
my $fake_radicals = qr(\xD0\xA4|\xBE\xB0|\xE7\xE8|\xCF\xB7|\xC7\xE3|\xB4\xA2|\xCB\xAE|\xDB\xBF|\xE3\xBB|\xB2\xBD|\xCB\xBB|\xD9\xA9|\xBD\xC1|\xC8\xC8|\xEF\xF4|\xCE\xE9|\xBD\xE9|\xE1\xCB|\xB9\xFE|\xC8\xAC|\xA1\xC3|\xD6\xF5|\xC5\xA9|\xA5\xCE|\xA5\xCF|\xA5\xDE|\xA5\xE6|\xA5\xE8);

# special characters
my $radmark = "\xA1\xF9";	# white circle
my $codemark = "\xA1\xFB";	# white star
my $vmark = "\xA2\xA6";		# white square
my $right_arrow = "\xA2\xAA";

# katakana EUC-JP -> JIS X 0208 mapping for "fake radicals"
$kanji2tag{"\xA5\xCE"} = "254E"; # no
$kanji2tag{"\xA5\xCF"} = "254F"; # ha
$kanji2tag{"\xA5\xDE"} = "255E"; # ma
$kanji2tag{"\xA5\xE6"} = "2566"; # yu
$kanji2tag{"\xA5\xE8"} = "2568"; # yo
$kanji2tag{"\xA1\xC3"} = "2143"; # |


# parse command line
unless (GetOptions("language=s" => \$lang,
		   "data-file=s" => \$datafile,
		   "info-file=s" => \$inffile,
		   "readme-file=s" => \$rdmfile,
		   "copyright-file=s" => \$cprfile,
		   "radical-file=s" => \$radfile,
		   "classical-radical-file=s" => \$cradfile,
		   "gaiji-file=s" => \$gaijifile,
		   "gaiji=i" => \$gaiji,
		   "add-CK=i" => \$addCK,
		   "print-codes=i" => \$printcodes,
		   "print-radicals=i" => \$printrads,
		   "key-codes=i" => \$keycodes,
 		   "key-radicals=i" => \$keyrads,
		   "large-kanji-bitmaps=i" => \$largebmp,
		   "debug=i" => \$debug) ) {
  exit 1;
}

# check language
if ($lang !~ /^en$|^de$|^fr$|^es$|^pt$/) {
  die "Language $lang not supported\n";
}

# the original English KanjiDic file is in EUC-JP encoding
if ($lang eq "en") {
  $encoding = "euc";
} else {
  $encoding = "utf8";
}


### construct gaiji table for halfwidth characters (fullwidth are simply
### gaiji name == JIS code)
open GT, "< $gaijifile" or die "$0: failed to open $gaijifile, $!\n";

foreach (<GT>) {
  my ($char, $name) = split;
  $gaiji_table{$char} = $name;
}

close (GT);


### read radical information:
# Jim Breen's multiradical method
open RAD, "<:gzip", $radfile or die "$0: failed to open $radfile, $!\n";

while (<RAD>) {
  next if /^#/;

  if (/^\$/) {
    ($radical, $stroke_cnt) = (split ' ')[1,2];
    $strcnt2radical[$stroke_cnt] .= "$radical\x00";
    next;
  }

  my @chars = unpack 'C*', $_;

  for (my $i = 0; $i < $#chars; $i += 2) {
    $kanji = pack "CC", $chars[$i], $chars[$i+1];

    $kanji2radical{$kanji} .= "$radical\x00";
  }
}

close (RAD);

# the 214 classical Kangxi radicals
open CRAD, $cradfile or die "$0: failed to open $cradfile, $!\n";

while (<CRAD>) {
  next if /^#/;

  if (/^S(\d+)/) {
    $stroke_cnt = $1;
    next;
  }

  my ($n, $kanji) = split '/';

  $cradcheck{$kanji} = 1 unless m!^\*! or $n == 2;
  $n =~ s!^\*!!;
  $cradlist[$n] = $kanji;
  $strcnt2class_radical[$stroke_cnt] .= "$kanji\x00";
  $class_radical2strcnt{$kanji} = $stroke_cnt;
}

close (CRAD);


### start conversion
print "\n*** Creating KanjiDic for language $lang\n\n";
print "*** Reading file $datafile...\n";

open DF, "<:gzip", $datafile or die "$0: failed to open $datafile\n";

# parse file (EDICT formatted)
while (<DF>) {

  my ($head, $content, $codes);
  my ($kanji, $tag, $stroke_cnt, $xcodes);
  my ($item, $readings, $onkun, $nanori, $T2reading, $chinese, $korean);
  my $sflag = 1;
  my $cnt = 0;


  next if /^#/;
  next if /^\s*$/;
  chomp;

  if (/(.*?){(.*)/) {
    $head = $1;
    $content = $2;

    $head = jcode($head, $encoding)->euc if $encoding ne "euc";
    $head =~ s!\s*$!!;

    if ($lang ne "en") {
      $content = from_utf8 ("-string" => $content, "-charset" => "latin1");
      $content = to_ascii($content) unless $gaiji;
    }

    $content =~ s!^\s*{\s*!!;
    $content =~ s!\s*}\s*$!!;
    $content =~ s!\s*} {\s*!\x00!g;
    $content =~ s!\s+! !g;

    if ($head =~ /(.*) T1 (.*) T2 (.*)/) {
      $head = $1;
      $nanori = $2;
      $T2reading = $3;
    } elsif ($head =~ /(.*) T1 (.*)/) {
      $head = $1;
      $nanori = $2;
    } elsif ($head =~ /(.*) T2 (.*)/) {
      $head = $1;
      $T2reading = $2;
    }

    foreach my $entry (split ' ', $head) {
      $cnt++;

      if ($cnt == 1) { $kanji = $entry; next; }
      if ($entry =~ /^Y(.*)/) { $chinese .= "$1 "; next }
      if ($entry =~ /^W(.*)/) { $korean .= "$1 "; next }

      if ($cnt == 2) { $tag = $entry }; # use JIS code for tagging
      if ($sflag and $entry =~ /^S(\d+)/) { $stroke_cnt = $1; $sflag = 0 }

      # WWWJDIC doesn't make links for these but rather outputs them
      if ($entry =~ /^($xref_codes)/) {	$xcodes .= "$entry\x00" }

      if ($entry =~ /^X(($xref_codes).*)/) {
	$kanji_xrefs{$kanji} .= "$1\x00";
      } elsif ($entry =~ /^[0-9A-Z]/) {
	$codes .= "$entry ";
      } else {
	$onkun .= "$entry ";
      }
    }

    # kanji->tag and tag->kanji association
    $kanji2tag{$kanji} = $tag;	# kanji to JIS X 0208
    $tag2kanji{$tag} = "$kanji\x00";

    foreach my $xc (split '\x00', $xcodes) {
      $tag2kanji{$xc} .= "$kanji\x00";
    }

    $kanji2strcnt{$kanji} = $stroke_cnt;

    # clean up
    $codes =~ s!\s*$!!;
    $onkun =~ s!\s*$!!;
    $chinese =~ s!\s*$!!;
    $korean =~ s!\s*$!!;

    $item = "$kanji";
    $item .= " $onkun" if $onkun ne "";
    $item .= "  N $nanori" if $nanori ne "";
    $item .= "  R $T2reading" if $T2reading ne "";
    $item .= "  C $chinese" if $addCK and $chinese ne "";
    $item .= "  K $korean" if $addCK and $korean ne "";
    $item =~ s!\s*$!!;

    if ($addCK) {
      $readings = "$onkun " . "$nanori " . "$T2reading " . "$chinese " .
                  $korean;
    } else {
      $readings = "$onkun " . "$nanori " . $T2reading;
    }

    # prepare forward indexing
    push @forward, "$item\x01$kanji\x01$content\x01$readings\x01$tag\x01$codes";

    # prepare reverse indexing: readings->kanji
    foreach my $r (split ' ', $readings) {
      $r =~ s!\.!!g;		# remove separating dots
      $reverse{$r} .= "$stroke_cnt $kanji\x00";
    }

    # prepare meaning->kanji indexing
    $content = to_ascii($content);
    $content =~ s!\xB0!\xA1\xEB!g; # degree sign

    foreach my $m (split '\x00', $content) {
      $m =~ s!\[.*?\]!!g;	# do not index text in brackets and
      $m =~ s!\(.*?\)!!g;	# parenthesis
      next if $m eq "";

      # split comma separated entries
      foreach my $m2 (split /,/, $m) {
        $m2 =~ s!\s+$!!;
        $m2 =~ s!^\s*!!;

	# arbitrary data pruning
        next if $m2 eq "" or length($m2) < 2 or length($m2) > 30;

        $meaning{$m2} .= "$stroke_cnt $kanji\x00";
      }
    }
  } else {			# error checking
    print "### WARNING: Invalid line!  Check input!\n";
  }
}

close (DF);

# index by kanji
print "*** Indexing by kanji...\n";

foreach my $arg (@forward) {
  my ($item, $kanji, $content, $readings, $tag, $codes) = split '\x01', $arg;

  print "$item : $content\n" if $debug;
  register_kanji($item, $kanji, $content, $readings, $tag, $codes);
}

undef @forward;

print "*** Indexing by readings...\n";
register(\%reverse);
undef %reverse;

print "*** Indexing by meanings...\n";
register(\%meaning);
undef %meaning;

print "*** Writing menu and copyright information...\n\n";
write_menu();
write_copy();


exit 0;
##### bye, bye!



##### subroutines

sub register_kanji {
  my ($item, $kanji, $meaning, $readings, $tag, $codes) = @_;

  my ($entry, $xref_text, $xref_marker, $symbol, $radical, $rcode, $tmp);
  my %xfound;


  $entry = "<entry><heading>$kanji</heading><tag name=\"$tag\">";

  ### search keys
  $entry .= "<key name=\"$kanji\">";

  foreach my $r (split ' ', $readings) {
    $r =~ s!(.*)\..*!\1!;	# remove separating dots
    $entry .= "<key type=\"conditional\" name=\"$r\">";
  }

  foreach my $c (split ' ', $codes) {
    if ($keycodes) {
      $entry .= "<key name=\"$c\">";
    }

    if ($c =~ /$non_unique_codes/) {
      $entry .= "<key type=\"conditional\" name=\"$c\">";
    }
  }

  foreach my $r (split '\x00', $kanji2radical{$kanji}) {
    $entry .= "<key type=\"conditional\" name=\"$r\">";
  }

  # text to appear in "results"
  $entry .= "<keyword>$item</keyword><nl><indent level=\"2\">";

  ### kanji bitmap graphics
  if ($largebmp) {
    $entry .= "<image name=\"$tag\"></image><nl>";
  }

  ### meanings (gaiji replacement)
  $meaning =~ s/\x00/; /g;
  $meaning =~ s!([\200-\377])!<gaiji type="half" name="$gaiji_table{$1}">!g
    if $gaiji;

  $entry .= "$meaning<nl>";

  ### cross references
  if (defined $kanji_xrefs{$kanji}) {
    foreach my $xcode (split '\x00', $kanji_xrefs{$kanji}) {

      # write reference marker only once
      if (!defined $xfound{$xcode} and $xcode =~ /^($xref_mark_types).*/) {
	$xref_marker = $1;
	$xfound{$xcode} = 1;
      }

      if ($xcode !~ /^J1(.*)/) {
	$xcode =~ s/^J0//;	# JIS X 0208 references

        foreach my $k (split '\x00', $tag2kanji{$xcode}) {
          if (defined $xref_marker) {
	    $xref_text .= " $xref_marker ";
	    undef $xref_marker;
	  } else {
	    $xref_text .= " ";
	  }

	  $xref_text .= "<ref target=\"$kanji2tag{$k}\">$k</ref>";
	}
      } else {			# JIS X 0212 references
        $tmp = uc($1);
	$xref_text .= " <gaiji type=\"full\" name=\"$tmp\">";
      }
    }

    $entry .= "$vmark$xref_text<nl>" if $xref_text;
  }

  ### print dictionary codes
  if ($codes =~ m/ (C)(\d+) /) {
    $rcode = $1;
    $radical = $cradlist[$2];
  } elsif ($codes =~ m/ (B)(\d+) /) {
    $rcode = $1;
    $radical = $cradlist[$2];
  }

  # store radical->kanji association for later use
  $class_radical2kanji{$radical} .= "$kanji\x00";

  if ($printcodes) {
    if (defined $cradcheck{$radical}) {
      $symbol = $radical;
    } else {
      $symbol = "<gaiji type=\"full\" name=\"r$kanji2tag{$radical}\">";
    }

    # add radical to B or C code, respectively
    $codes =~ s! ($rcode\d+) ! $1($symbol) !;

    $entry .= "$codemark $codes<nl>";
  }

  ### print kanji components
  if ($printrads) {
    $entry .= $radmark;

    foreach my $r (split '\x00', $kanji2radical{$kanji}) {
      if ($r =~ /$fake_radicals/) {
	$entry .= " <gaiji type=\"full\" name=\"r$kanji2tag{$r}\">";
      } else {
	$entry .= " $r";
      }
    }

    $entry .= "<nl>";
  }

  FreePWING_write($entry);
}


sub register {
  my $hash = shift;


  foreach my $k (keys %$hash) {
    my ($entry, @save, @sorted, %chars);

    foreach my $ele (split '\x00', $$hash{$k}) {
      next if $ele eq "";

      # ignore duplicates
      if (!defined($chars{$ele}) ) {
        $chars{$ele} = 1;
      } else {
        next;
      }

      push @save, $ele;
    }

    # sort by stroke count in ascending order
    foreach my $ele (sort stroke_sort @save) {
      my ($stroke, $kanji) = split ' ', $ele;

      $sorted[$stroke] .= "$kanji\x00";
    }

    $k = FreePWING_encode($k);
    $entry = "<entry><heading>$k</heading>" .
      "<key name=\"$k\">" .
	"<keyword>$k</keyword><nl><indent level=\"2\">";

    # precede each line with the stroke count
    for (my $i = 1; $i <= $#sorted; $i++) {
      next if !defined $sorted[$i];

      $entry .= sprintf "%2u:", $i;

      foreach my $c (split '\x00', $sorted[$i]) {
	$entry .= " <ref target=\"$kanji2tag{$c}\">$c</ref>";
      }

      $entry .= "<nl>";
    }

    FreePWING_write($entry);
  }

  FreePWING_write("<nl>");
}


sub write_menu {
  my $howtxt = "How to use KanjiDic";
  my $doctxt = "KanjiDic documentation";
  my $searchtxt = "Search by classical radicals";
  my $cradtxt = "The 214 classical Kangxi radicals";
  my $radtxt = "Radical/component element information";
  my ($l, $cnt);


  FreePWING_write("<menu>" .
		  "<ref target=\"M1\">$right_arrow $howtxt</ref><nl>" .
		  "<ref target=\"M2\">$right_arrow $doctxt</ref><nl>" .
		  "<ref target=\"M3\">$right_arrow $searchtxt</ref><nl>" .
		  "<ref target=\"M4\">$right_arrow $cradtxt</ref><nl>" .
		  "<ref target=\"M5\">$right_arrow $radtxt</ref><nl>");

  foreach my $file ($rdmfile, $inffile) {
    open IN, "< $file" or die "$0: failed to open $file\n";

    $l++;
    FreePWING_write("<menu><tag name=\"M$l\">");

    while (<IN>) {
      my $contents = $_;
      $contents = FreePWING_encode($contents) if $l > 1;
      FreePWING_write("$contents<nl>");
    }

    close(IN);
  }

  ## search by classical Kangxi radicals
  FreePWING_write("<menu><tag name=\"M3\">$searchtxt: " .
		  "The radicals are sorted according to their stroke count.  " .
		  "The kanji lists are preceded by the residual stroke count ".
		  "on the linked pages.<nl>");

  for (my $i = 1; $i <= $#strcnt2class_radical; $i++) {
    next if !defined $strcnt2class_radical[$i];

    my $entry = sprintf "<nl>%2u:<nl>", $i;

    foreach my $r (split '\x00', $strcnt2class_radical[$i]) {
      $cnt++;

      if (defined $cradcheck{$r}) {
	$entry .= " <ref target=\"Mrad$cnt\">$r</ref>";
      } else {
	$entry .= " <ref target=\"Mrad$cnt\">" .
		     "<gaiji type=\"full\" name=\"r$kanji2tag{$r}\"></ref>";
      }
    }

    FreePWING_write($entry);
  }

  FreePWING_write("<nl><nl>");
  $cnt = 0;

  for (my $i = 1; $i <= $#strcnt2class_radical; $i++) {
    next if !defined $strcnt2class_radical[$i];

    foreach my $r (split '\x00', $strcnt2class_radical[$i]) {
      $cnt++;

      my (@sorted, $entry);

      if (defined $cradcheck{$r}) {
	$entry = "<menu><tag name=\"Mrad$cnt\">" .
	  "<ref target=\"$kanji2tag{$r}\">$r</ref>($i)<nl>";
      } else {
	$entry = "<menu><tag name=\"Mrad$cnt\">" .
	  "<gaiji type=\"full\" name=\"r$kanji2tag{$r}\">($i)<nl>";
      }

      foreach my $k (split '\x00', $class_radical2kanji{$r}) {
	next if $k eq $r and defined $cradcheck{$k};
	$sorted[$kanji2strcnt{$k}] .= "$k\x00";
      }

      # precede each line with the residual stroke count
      for (my $j = $i; $j <= $#sorted; $j++) {
	next if !defined $sorted[$j];

	$entry .= sprintf "%2u:", $j - $i;

	foreach my $k (split '\x00', $sorted[$j]) {
	  $entry .= " <ref target=\"$kanji2tag{$k}\">$k</ref>";
	}

	$entry .= "<nl>";
      }

      FreePWING_write($entry);
    }
  }

  FreePWING_write("<nl><nl>");


  ## classical Kangxi radicals
  FreePWING_write("<menu><tag name=\"M4\">$cradtxt: The radicals " .
		  "are sorted according to their stroke count.<nl>");

  for (my $i = 1; $i <= $#strcnt2class_radical; $i++) {
    next if !defined $strcnt2class_radical[$i];

    my $entry = sprintf "<nl>%2u:<nl>", $i;

    foreach my $r (split '\x00', $strcnt2class_radical[$i]) {
      if (defined $cradcheck{$r}) {
	$entry .= " <ref target=\"$kanji2tag{$r}\">$r</ref>";
      } else {
	$entry .= " <gaiji type=\"full\" name=\"r$kanji2tag{$r}\">";
      }
    }

    FreePWING_write($entry);
  }

  FreePWING_write("<nl><nl>");


  ## radicals/component elements
  FreePWING_write("<menu><tag name=\"M5\">$radtxt: The radicals " .
		  "are sorted according to their stroke count.<nl>");

  for (my $i = 1; $i <= $#strcnt2radical; $i++) {
    next if !defined $strcnt2radical[$i];

    my $entry = sprintf "<nl>%2u:<nl>", $i;

    foreach my $r (split '\x00', $strcnt2radical[$i]) {
      if (defined $kanji2tag{$r} and !($r =~ /$fake_radicals/) ) {
	$entry .= " <ref target=\"$kanji2tag{$r}\">$r</ref>";
      } else {
	$entry .= " <gaiji type=\"full\" name=\"r$kanji2tag{$r}\">";
      }
    }

    FreePWING_write($entry);
  }

  FreePWING_write("<nl><nl>");


  ## pseudo search key to access menu information through standard search
  FreePWING_write("<entry><heading>Menu</heading><key name=\"_menu\">" .
		  "<ref target=\"M1\">$right_arrow $howtxt</ref><nl>" .
		  "<ref target=\"M2\">$right_arrow $doctxt</ref><nl>" .
		  "<ref target=\"M3\">$right_arrow $searchtxt</ref><nl>" .
		  "<ref target=\"M4\">$right_arrow $cradtxt</ref><nl>" .
		  "<ref target=\"M5\">$right_arrow $radtxt</ref><nl>" .
		  "<context>"		# force new context for "real" dictionary
		 );
}


sub write_copy {

  my $contents;


  open IN, "< $cprfile" or die "$0: failed to open $cprfile\n";

  while (<IN>) {
    s/\n/<nl>/;
    $contents .= $_;
  }

  FreePWING_write("<copyright>$contents");

  close(IN);
}


sub stroke_sort {
  my ($x, $y) = ($a, $b);

  $x =~ s!(\d+) .*!$1!;
  $y =~ s!(\d+) .*!$1!;

  $x <=> $y;
}
