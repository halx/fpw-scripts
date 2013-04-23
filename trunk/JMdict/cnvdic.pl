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
# convert Jim Breen's JMdict (Rev 1.07) to JIS X 4081 (EPWING subset) format
# needs FreePWING (http://www.sra.co.jp/people/m-kasahr/freepwing/) and
# other libraries
#



use strict;
use PerlIO::gzip;
use Getopt::Long;		# actually already used by FreePWING
use FreePWING::FPWUtils::MarkupInterface qw(FreePWING_encode FreePWING_write);
use Jcode;
use Lingua::DE::ASCII qw(to_ascii);
use Unicode::MapUTF8 qw(from_utf8);
use XML::Twig;
use Text::Kakasi;

use subs qw(process_entry, register, write_menu, write_copy, euc_chars, warn_msg);


my ($lang, $romaji, $datafile, $inffile, $rdmfile, $cprfile, $gaijifile);
my ($dict_version, $debug);
my ($printfrq, $kakasi, $ign, $jpto, $tojp, $ent_seq);
my ($leftb, $rightb, $middot, $right_arrow) =
  ("\xA1\xDA", "\xA1\xDB", "\xA1\xA6", "\xA2\xAA");  # some handy characters


my @pri_list = ('ichi1', 'jdd1', 'gai1', 'spec1', 'news1');

my %lang_list = ('eng' => 'English',
		 'fre' => 'French',
		 'ger' => 'German',
		 'rus' => 'Russian',
		 'dut' => 'Dutch',
		 'nor' => 'Norwegian');  # supported languages

my (%inverse, %gaiji_table);



# parse command line
unless (GetOptions('language=s' => \$lang,
		   'romaji-key=i' => \$romaji,
		   'data-file=s' => \$datafile,
		   'info-file=s' => \$inffile,
		   'readme-file=s' => \$rdmfile,
		   'copyright-file=s' => \$cprfile,
		   'gaiji-file=s' => \$gaijifile,
		   'version-string=s' => \$dict_version,
		   'debug=i' => \$debug) ) {
  exit 1;
}

if (!grep (/^$lang$/, keys %lang_list) ) {
  die "$lang not supported\n";
}

# construct gaiji table
open GT, "< $gaijifile" || die "$0: failed to open the file, $!: $gaijifile\n";

while (<GT>) {
  my ($char, $name) = split;
  $gaiji_table{$char} = $name;
}

# kana/romaji conversion (if requested)
$kakasi = Text::Kakasi->new('-Ha', '-Ka', '-Ea', '-c', '-oeuc') if $romaji;

# initialize FPW parser, write menu and copyright information
print "\n*** Creating $lang_list{$lang} JMdict in EPWING format\n\n";

print "*** Writing menu and copyright information...\n";
write_menu();
write_copy();

$tojp = $jpto = $ign = 0;

# parse dictionary file and index by kanji/kana
print "*** starting Japanese/$lang_list{$lang} conversion...\n";

open DATA, '<:gzip', "$datafile" or
  die "$0: failed to open the file, $!: $datafile\n";

my $entry = new XML::Twig(twig_handlers => {'entry' => \&process_entry}, NoExpand => 1);
$entry->parse(\*DATA);
$entry->purge;

close (DATA);

print "*** $jpto entries processed\n";
print "*** $ign entries ignored\n";

# index by translation
print "*** starting $lang_list{$lang}/Japanese conversion...\n";

foreach my $k (keys %inverse) {
  my $contents;


  foreach my $item (split '\x00', $inverse{$k}){
    next if $item eq '';

    $item =~ s!;!$middot!g;
    $contents .= "$item; ";
  }

  $contents =~ s!; $!!;
  $tojp++;

  register($k, $k, $contents);
}

print  "*** $tojp entries processed\n\n";
printf "*** %i entries created\n\n", $jpto + $tojp;
print  "*** finished processing file $datafile\n\n";

exit 0;
### end of main



###  subroutines

sub process_entry {
  my ($twig, $entry) = @_;

  my ($item, $kanji, $kana, $stagk, $stagr, $pos, $field, $misc, $s_inf);
  my ($dial, $trans, $trans2, $contents, $check_entry, $found);
  my @sense;



  # exactly one ent_seq element
  $ent_seq = $entry->first_child_trimmed_text('ent_seq');

  # <k_ele*>: kanji
  foreach my $k_ele ($entry->descendants('k_ele') ) {
    my ($inf, $priority);
    my $keb = $k_ele->first_child('keb');  # exactly one keb element


    foreach my $ke_inf ($k_ele->descendants('ke_inf') ) {
      $inf = $ke_inf->first_child->trimmed_text() . ',';
    }

    foreach my $ke_pri ($k_ele->descendants('ke_pri') ) {
      my $pri = $ke_pri->first_child->trimmed_text();
      $priority = grep(/$pri/, @pri_list);
    }

    $kanji .= $keb->trimmed_text;

    if (defined $inf) {
      $inf =~ s!(&|;|,$)!!g;
      $kanji .= "($inf)";
    }

    $kanji .= '(P)' if $priority;
    $kanji .= ';';
  }
  # </k_ele>


  # <r_ele+>: reading
  # not processed: <re_nokanji>
  foreach my $r_ele ($entry->descendants('r_ele') ) {
    my ($inf, $restr, $priority);
    my $reb = $r_ele->first_child('reb');  # exactly one reb element


    foreach my $re_inf ($r_ele->descendants('re_inf') ) {
      $inf = $re_inf->first_child->trimmed_text() . ',';
    }

    foreach my $re_restr ($r_ele->descendants('re_restr') ) {
      $restr = $re_restr->first_child->trimmed_text() . ',';
    }

    foreach my $re_pri ($r_ele->descendants('re_pri') ) {
      my $pri = $re_pri->first_child->trimmed_text();
      $priority = grep(/$pri/, @pri_list);
    }

    $kana .= $reb->trimmed_text();

    if (defined $restr) {
      $restr =~ s!,$!!;
      $kana .= "($restr)";
    }

    if (defined $inf) {
      $inf =~ s!(&|;|,$)!!g;
      $kana .= "($inf)";
    }

    $kana .= '(P)' if $priority;
    $kana .= ';';
  }
  # </r_ele>

  if ($kana eq '') {
    warn_msg("No keys available!", 1);
    return;
  }


  # <info>
  # not processed at the moment
  # </info>

  # <sense>
  # not processed: <xref>, <ant>, <example>, <lsource>
  foreach my $s ($entry->descendants('sense') ) {
    my %sdata;


    # kanji lexem
    foreach my $sk ($s->descendants('stagk') ) {
      $sdata{'stagk'} .= $sk->first_child->trimmed_text() . ',';
    }

    # reading lexem
    foreach my $sr ($s->descendants('stagr')) {
      $sdata{'stagr'} .= $sr->first_child->trimmed_text() . ',';
    }

    # part of speech
    foreach my $p ($s->descendants('pos') ) {
      $sdata{'pos'} .= $p->first_child->trimmed_text() . ',';
    }

    # field of application
    foreach my $f ($s->descendants('field')) {
      $sdata{'field'} .= $f->first_child->trimmed_text() . ',';
    }

    # other relevant information
    foreach my $m ($s->descendants('misc') ) {
      $sdata{'misc'} .= $m->first_child->trimmed_text() . ',';
    }

    # sense information
    foreach my $si ($s->descendants('s_inf') ) {
      $sdata{'s_inf'} .= $si->first_child->trimmed_text() . ',';
    }

    # regional dialect information
    foreach my $di ($s->descendants('dial') ) {
      $sdata{'dial'} .= $di->first_child->trimmed_text() . ',';
    }

    # translation
    foreach my $g ($s->descendants('gloss') ) {
      my $text = $g->first_child->trimmed_text();

      if ($g->att('xml:lang') eq $lang) {
	if ($lang ne 'rus') {
	  $text = from_utf8(-string => $text, -charset => 'latin1');
	} else {  # special case: cyrillic characters
	  $text = jcode($text, 'utf8')->euc;
	}

	$sdata{'gloss'} .= "$text; ";
	$trans2 .= "$text\x00";
      } else {
	next;
      }
    }

    next if !defined $sdata{'gloss'};

    $found = 1;
    push @sense, \%sdata;	# store senses for later processing
  }
  # </sense>
  # ...and end of XML data parsing


  if (!$found) {
    $twig->purge;
    return;
  }

  ## prepare forward indexing
  $kana =~ s!;$!!;
  $kana = jcode($kana, 'utf8')->euc;

  $kanji =~ s!;$!!;
  $kanji = jcode($kanji, 'utf8')->euc;

  if ($kanji ne '') {
    $item = "$kanji$leftb$kana$rightb";
  } else {
    $kanji = '';
    $item = $kana;
  }

  $item =~ s!;!$middot!g;

  # remove text in parentheses for indexing
  $kanji =~ s!\(.*?\)!!g;
  $kana =~ s!\(.*?\)!!g;

  # process and format contents field
  my $cnt = 0;
  foreach my $d (@sense) {

    if ($#sense > 0) {
      $cnt++;
      $contents .= "<b>$cnt</b> ";
    }

    $trans = $$d{'gloss'};

    if (defined $trans) {
      $trans =~ s!; $!!;

      FreePWING_encode($trans);

      # convert to gaiji if necessary: assume one-byte characters only
      if ($lang ne 'rus') {
	$trans =~
	  s!([\x80-\xFF])!<gaiji type=\"half\" name=\"$gaiji_table{$1}\">!g;
      }

      $contents .= "$trans ";
    }

    # <pos> only used for first entry?
    $pos = $$d{'pos'};

    if (defined $pos) {
      $pos =~ s!(&|;)!!g;
      $pos =~ s!,$!!;
      $contents .= '<i>' . jcode($pos, 'utf8')->euc . '</i> ';
    }

    $stagk = $$d{'stagk'};

    if (defined $stagk) {
      $stagk =~ s!,$!!;
      $contents .= '(' . jcode($stagk, 'utf8')->euc . ' only) ';
    }

    $stagr = $$d{'stagr'};

    if (defined $stagr) {
      $stagr =~ s!,$!!;
      $contents .= '(' . jcode($stagr, 'utf8')->euc . ' only) ';
    }

    $field = $$d{'field'};

    if (defined $field) {
      $field =~ s!(&|;)!!g;
      $field =~ s!,$!!;
      $contents .= '{' . jcode($field, 'utf8')->euc . '} ';
    }

    $misc = $$d{'misc'};

    if (defined $misc) {
      $misc =~ s!(&|;)!!g;
      $misc =~ s!,$!!;
      $contents .= '(' . jcode($misc, 'utf8')->euc . ') ';
    }

    $s_inf = $$d{'s_inf'};

    if (defined $s_inf) {
      $s_inf =~ s!,$!!;
      $contents .= '(' . jcode($s_inf, 'utf8')->euc . ')';
    }

    $dial = $$d{'dial'};

    if (defined $dial) {
      $dial =~ s!,$!!;
      $contents .= '[' . jcode($dial, 'utf8')->euc . ']';
    }

    $contents =~ s!\s+$!!;
    $contents .= "<nl>";
  }

  $jpto++;

  $check_entry = "$item$kanji$kana$contents";

  if ($check_entry =~ /\x8F[\xA1-\xFE][\xA1-\xFE]/) {
    warn_msg("non JIS X 0208 character found!", 1);
    return;
  }

  register($item, "$kanji\x00$kana", $contents);


  ## store data for inverse indexing
  if ($kanji ne '') {
    $item = "$kanji$leftb$kana$rightb";
  } else {
    $item = $kana;
  }

  $trans2 =~ s!\(.*?\)!!g;

  if ($lang ne 'rus') {
    $trans2 = to_ascii($trans2);
    $trans2 = euc_chars($trans2);
  }

  foreach my $k (split '\x00', $trans2) {
    next if $k =~ /^[0-9_><'([{,:=?+-]/;
    next if length($k) < 2 or length($k) > 30;  # arbitrary limit

    # trim keys
    $k =~ s!^\s*!!;
    $k =~ s!\s*$!!;

    $inverse{$k} .= "$item\x00";
  }

  $twig->purge;
}


sub register() {
  my ($item, $keys, $contents) = @_;

  my %dupl;
  my ($kanji, $kana, $entry, $head, $lcnt, $rk);


  $keys =~ /(.*)\x00(.*)/;

  if (defined $1) {
    if ($1 ne '') {
      $head = $1;
    } else {
      $head = $2;		# kana must be present
    }

    $kanji = $1;
    $kana = $2;
  } else {
    $head = $keys;
    $kanji = $keys;
    $kana = '';
  }

  $head =~ s!;!$middot!g;
  $entry = "<entry><heading>$head</heading>";

  print STDERR "[$ent_seq] $item ($kanji,$kana): $contents\n" if $debug > 0;

  # search keys
  $lcnt = 0;

  foreach my $list ($kanji, $kana) {
    foreach my $k (split /;/, $list) {
      $k =~ s!^\s*!!;
      $k =~ s!\s*$!!;

      # the backend doesn't like the following characters
      $k =~ s!$middot!.!;

      # ignore duplicates
      if (!defined($dupl{$k}) ) {
        $dupl{$k} = 1;
      } else {
        next;
      }

      $k =~ s!"!\\"!g;            # mask quotes
      $entry .= "<key name=\"$k\">";

      # add romaji keys if requested
      if ($romaji and $list eq $kana) {
        $rk = $kakasi->get($k);
        $rk =~ s!\^!-!g;

	# the backend doesn't like single '-'
	unless ($rk =~ /^-$/) {
	  $entry .= "<key name=\"$rk\">" if $rk ne '';
	}
      }

      $lcnt++;
    }
  }

  if ($lcnt == 0) {
    warn_msg("No keys available!", 1);
    return;
  }

  $entry .= "<keyword>$item</keyword><nl><indent level=\"2\">";
  $entry .= $contents;
  print STDERR "  => $entry\n" if $debug > 1;
  FreePWING_write($entry);
}


sub write_menu {

  my $l = 0;


  FreePWING_write('<menu>' .
		  '<ref target="M1">About this conversion</ref><nl>' .
		  '<ref target="M2">General dictionary license statement</ref><nl>' .
		  '<ref target="M3">JMDict information</ref><nl>');

  foreach my $file ($rdmfile, $cprfile, $inffile) {
    open IN, "< $file" or die "$0: failed to open $file\n";

    $l++;
    FreePWING_write("<menu><tag name=\"M$l\">");

    while (<IN>) {
      my $contents = $_;
      $contents = FreePWING_encode($contents) if $l == 1;
      FreePWING_write("$contents<nl>");
    }

    close(IN);
  }

  ## pseudo search key to access menu information through standard search
  FreePWING_write("<entry><heading>Menu</heading><key name=\"_menu\">" .
		  "<ref target=\"M1\">$right_arrow About this conversion</ref><nl>" .
		  "<ref target=\"M2\">$right_arrow General dictionary license statement</ref><nl>" .
		  "<ref target=\"M3\">$right_arrow JMDict information</ref><nl>" .
                  "<context>"           # force new context for "real" dictionary
                 );

  ## pseudo search key to access version information through standard search
  FreePWING_write("<entry><heading>version information</heading><key name=\"_version\">" .
                  "<keyword>version information</keyword><nl>" .
		  "<indent level=\"2\">$dict_version<nl>" .
                  "<context>"           # force new context for "real" dictionary
                 );
}


sub write_copy {

  my $contents;


  open IN, "< $cprfile" or die "$0: failed to open $cprfile\n";

  while (<IN>) {
    $contents .= FreePWING_encode($_) . "<nl>";
  }

  close IN;

  FreePWING_write("<copyright>$contents");
}


# convert a few characters which are both in Latin1 and EUC-JP
sub euc_chars {
  my $string = $_[0];

  $string =~ s!\xA2!\xA1\xF1!g; # cent
  $string =~ s!\xA5!\xA1\xEF!g; # yen
  $string =~ s!\xA7!\xA1\xF8!g; # section
  $string =~ s!\xA8!\xA1\xAF!g; # diaeresis
  $string =~ s!\xB0!\xA1\xEB!g; # degree
  $string =~ s!\xB1!\xA1\xDE!g; # plusminus
  $string =~ s!\xB4!\xA1\xAD!g; # accute accent
  $string =~ s!\xF7!\xA1\xE0!g; # division

  return $string;
}


# warning message
sub warn_msg {
  my ($text, $ignore) = @_;


  $ign++;
  print STDERR "[$ent_seq] W> $text";

  if ($ignore) {
    print STDERR " Ignoring entry...";
  }

  print STDERR "\n";
}
