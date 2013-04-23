#!/usr/bin/perl -w
#
# Copyright (C) 2004-2005 Hannes Loeffler
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
# convert XML formatted kanjidic2 to JIS X 4081 format (EPWING subset)
# needs FreePWING (http://www.sra.co.jp/people/m-kasahr/freepwing/)
#


use strict;
use Getopt::Long;
use XML::Twig;



my $lang = "en";
my $datafile = "kanjidic2.xml";


my $prog = $0;
$prog =~ s{^.*/}{};             # basename

# parse command line
die &help unless (GetOptions("outfile=s" => $outfile,
		   "lang=s" => \$lang,
                   "help" => \&help) );

$datafile = $ARGV[0] if $ARGV[0];

my $kanjidic = new XML::Twig(twig_handlers =>
			     {"character" => \&process_character,
			      "header" => \&process_header}
			    );

$kanjidic->parsefile($datafile);
$kanjidic->purge;

close OUT;

exit 0;



### subroutines

sub process_character {
  my ($twig, $character) = @_;

  my $kanji;
  my ($ucs, $jis208, $jis212, $jis213);
  my ($classical, $nelson);
  my ($grade, $stroke, %variant, $frequency, $jlpt);
  my $radical_names;
  my ($nelson_c, $nelson_n, $halpern_njecd, $halpern_kkld, $heisig,
      $gakken, $oneill_names, $oneill_kk, $moro_vol, $moro_page, $moro,
      $henshall, $sh_kk, $sakade, $henshall3, $tutt_cards, $crowley,
      $kanji_in_context, $busy_people, $kodansha_compact);
  my ($skip, $sh_desc, $four_corner, $deroo, $misclass);
  my ($pinyin, $korean_r, $ja_on, $ja_kun, $nanori, $meaning);
  my $readings;


  $kanji = $character->first_child_trimmed_text('kanji');

  # <codepoint>
  foreach my $codepoint ($character->descendants("codepoint") ) {
    foreach my $cp_value ($codepoint->descendants("cp_value") ) {
      my $cp_type = $cp_value->att("cp_type");
      my $val = $cp_value->first_child->trimmed_text;

      $ucs = "$val" if $cp_type eq "ucs";
      $jis208 = "$val" if $cp_type eq "jis208";

      # skip JIS X 0212/0213 kanji
      return if $cp_type eq "jis212" or $cp_type eq "jis213";
    }
  }

  # <radical>
  foreach my $radical ($character->descendants("radical") ) {
    foreach my $rad_value ($radical->descendants("rad_value") ) {
      my $rad_type = $rad_value->att("rad_type");
      my $val = $rad_value->first_child->trimmed_text;

      $classical = "$val" if $rad_type eq "classical";
      $nelson = "$val" if $rad_type eq "nelson";
    }
  }

  # <misc>
  $misc = $character->first_child_trimmed_text('misc');

  if (defined ($grade = ($misc->descendants("grade"))[0] ) ) {
    $grade = $grade->first_child->trimmed_text;
  }

  foreach my $stroke_count ($misc->descendants("stroke_count") ) {
    $stroke .= $stroke_count->first_child->trimmed_text. "\x00";
  }

  foreach my $var ($misc->descendants("variant") ) {
    my $var_type =$var->att("var_type");
    my $val = $var->first_child->trimmed_text;

    $variant{$var_type} .= "$val\x00";
  }

  if (defined ($frequency = ($misc->descendants("freq"))[0] ) ) {
    $frequency = $frequency->first_child->trimmed_text;
  }

  foreach my $rad_name ($misc->descendants("rad_name") ) {
    $radical_names .= $rad_name->first_child->trimmed_text . "\x00";
  }

  if (defined ($jlpt = ($misc->descendants("jlpt"))[0] ) ) {
    $jlpt = $jlpt->first_child->trimmed_text;
  }

  $radical_names =~ s/ $// if defined $radical_names;


  # <dic_number>
  if (defined ($dic_number = ($character->first_child_trimmed_text('dic_number') ) ) {
    foreach my $dic_ref ($dic_number->descendants("dic_ref") ) {
      my $dr_type = $dic_ref->att("dr_type");
      my $val = $dic_ref->first_child->trimmed_text;

      if ($dr_type eq "nelson_c") {$nelson_c = "$val"; next}
      if ($dr_type eq "nelson_n") {$nelson_n = "$val"; next}
      if ($dr_type eq "halpern_njecd") {$halpern_njecd = "$val"; next}
      if ($dr_type eq "halpern_kkld") {$halpern_kkld = "$val"; next}
      if ($dr_type eq "heisig") {$heisig = "$val"; next}
      if ($dr_type eq "gakken") {$gakken = "$val"; next}
      if ($dr_type eq "oneill_names") {$oneill_names .= "$val\x00"; next}
      if ($dr_type eq "oneill_kk") {$oneill_kk = "$val"; next}

      if ($dr_type eq "moro") {
	$moro_vol = $dic_ref->att("m_vol");
	$moro_page = $dic_ref->att("m_page");
	$moro = "$val";
	next;
      }

      if ($dr_type eq "henshall") {$henshall = "$val"; next}
      if ($dr_type eq "sh_kk") {$sh_kk = "$val"; next}
      if ($dr_type eq "sakade") {$sakade = "$val"; next}
      if ($dr_type eq "henshall3") {$henshall3 = "$val"; next}
      if ($dr_type eq "tutt_cards") {$tutt_cards = "$val"; next}
      if ($dr_type eq "crowley") {$crowley = "$val"; next}
      if ($dr_type eq "kanji_in_context") {$kanji_in_context = "$val"; next}
      if ($dr_type eq "busy_people") {$busy_people .= "$val\x00"; next}
      if ($dr_type eq "kodansha_compact") {$kodansha_compact .= "$val\x00"; next}
    }
  }

  # <query_code>
  if (defined ($query_code = ($character->first_child_trimmed_text('query_code') ) ) {
    foreach my $q_code ($query_code->descendants("q_code") ) {
      my $qc_type = $q_code->att("qc_type");
      my $val = $q_code->first_child->trimmed_text;

      if ($qc_type eq "skip") {$skip = "$val"; next}
      if ($qc_type eq "sh_desc") {$sh_desc = "$val"; next}
      if ($qc_type eq "four_corner") {$four_corner .= "$val\x00"; next}
      if ($qc_type eq "deroo") {$deroo = "$val"; next}
      if ($qc_type eq "misclass") {$misclass .= "$val\x00"; next}

      # attributes ignored: skip_misclass?
      #if ($qc_type eq "skip") {
      #  my $skip_misclass = $q_code->att("skip_misclass);
      #}
  }

  # <reading_meaning>
  foreach my $reading_meaning ($character->descendants("reading_meaning") ) {
    foreach my $rmgroup ($reading_meaning->descendants("rmgroup") ) {
      foreach my $reading ($rmgroup->descendants("reading") ) {
	my $r_type = $reading->att("r_type");

	# really ignore Hangul readings?
	next if $r_type eq "korean_h";

	my $val = $reading->first_child->trimmed_text;

	if ($r_type eq "pinyin") {$pinyin .= "$val\x00"; next}
	if ($r_type eq "korean_r") {$korean_r .= "$val\x00"; next}
	if ($r_type eq "ja_on") {$ja_on .= "$val\x00"; next}
	if ($r_type eq "ja_kun") {$ja_kun .= "$val\x00"; next}

	# attributes ignored: on_type?, r_status?
	# check type of on reading: kan, go, tou or kan'you or
	# if reading is approved "Jouyou kanji" reading
	#
	#if ($r_type eq "ja_on" or $r_type eq "ja_kun") {
	#  my $r_status = $reading->att("r_status");
	#}
	#if ($r_type eq "ja_on") {
	#  my $on_type = $reading->att("on_type");
	#}

      my $entxt;

      foreach my $trans ($reading_meaning->descendants("meaning") ) {
	my $m_lang = $trans->att("m_lang");
	my $txt;

	# guard against empty <meaning>'s
	if (defined $trans->first_child) {
	  $txt = $trans->first_child->trimmed_text;
	} else {
	  next;
	}

	$m_lang = "en" if !defined $m_lang;
	$entxt .= "$txt\x00" if $m_lang eq "en";
	$meaning .= "$txt\x00" if $m_lang eq $lang;
      }

      $meaning = $entxt if !defined $meaning;
    }

    foreach my $namer ($reading_meaning->descendants("nanori") ) {
      my $val = $namer->first_child->trimmed_text;
      $nanori .= "$val\x00";
    }
  }

  # create FreePWING entry...
  my $line = "$kanji ";

  $jis208 = kuten2jis($jis208);
  $line .= "$jis208 ";
  $line .= "U$ucs ";

  if (!defined $nelson) {
    $line .= "B$classical " if defined $classical;
  } else {
    $line .= "B$nelson ";
    $line .= "C$classical " if defined $classical;
  }

  $line .= "G$grade " if defined $grade;

  if (defined $stroke) {
    foreach my $sc (split '\x00', $stroke) {
      $line .= "S$sc " ;
    }
  }

  my $vars;

  foreach my $vs (keys %variant) {
    foreach my $v (split '\x00', $variant{$vs}) {
      if ($vs eq "jis208") {$v = kuten2jis($v); $vars .= "0XJ0$v\x00"; next}
      if ($vs eq "jis212") {$v = kuten2jis($v); $vars .= "1XJ1$v\x00"; next}
      #if ($vs eq "jis213") {$v = kuten2jis($v); $vars .= "2XJ2$v\x00"; next}
      if ($vs eq "njecd") {$vars .= "3XH$v\x00"; next}
      if ($vs eq "nelson") {$vars .= "4XN$v\x00"; next}
      if ($vs eq "deroo") {$vars .= "5XDR$v\x00"; next}
      if ($vs eq "s_h") {$vars .= "6XI$v\x00"}
      if ($vs eq "oneill") {$vars .= "7XO$v\x00"; next}
    }
  }

  if (defined $vars) {
    foreach my $v (sort split '\x00', $vars) {
      $v =~ s/^[0-7]//;
      $line .= "$v ";
    }
  }

  $line .= "F$frequency " if defined $frequency;

  $line .= "N$nelson_c " if defined $nelson_c;
  $line .= "V$nelson_n " if defined $nelson_n;
  $line .= "H$halpern_njecd " if defined $halpern_njecd;
  $line .= "DK$halpern_kkld " if defined $halpern_kkld;
  $line .= "L$heisig " if defined $heisig;
  $line .= "K$gakken " if defined $gakken;

  if (defined  $oneill_names) {
    foreach my $on (split '\x00', $oneill_names) {
      $line .= "O$on " ;
    }
  }

  $line .= "DO$oneill_kk " if defined $oneill_kk;
  $line .= "MN$moro " if defined $moro;
  $line .= "MP$moro_vol.$moro_page " if defined $moro_vol;
  $line .= "E$henshall " if defined $henshall;
  $line .= "IN$sh_kk " if defined $sh_kk;
  $line .= "DS$sakade " if defined $sakade;
  $line .= "DH$henshall3 " if defined $henshall3;
  $line .= "DT$tutt_cards " if defined $tutt_cards;
  $line .= "DC$crowley " if defined $crowley;
  $line .= "DJ$kanji_in_context " if defined $kanji_in_context;

  if (defined $busy_people) {
    foreach my $bp (split '\x00', $busy_people) {
      $line .= "DB$bp " ;
    }
  }

  if (defined $kodansha_compact) {
    foreach my $kc (split '\x00', $kodansha_compact) {
      $line .= "DG$kc " ;
    }
  }

  $line .= "P$skip " if defined $skip;
  $line .= "I$sh_desc " if defined $sh_desc;

  if (defined $four_corner) {
    foreach my $fc (split '\x00', $four_corner) {
      $line .= "Q$fc " ;
    }
  }

  $line .= "DR$deroo " if defined $deroo;

  if (defined $misclass) {
    foreach my $mc (split '\x00', $misclass) {
      $line .= "Z$mc " ;
    }
  }

  my $tmp;

  if (defined $pinyin) {
    $tmp = $pinyin;
    $tmp =~ s!\x00$!!;
    $tmp =~ s!\x00! Y!g;
    $line .= "Y$tmp ";
  }

  if (defined $korean_r) {
    $tmp = $korean_r;
    $tmp =~ s!\x00$!!;
    $tmp =~ s!\x00! W!g;
    $line .= "W$tmp ";
  }

  if (defined $ja_on) {
    $tmp = $ja_on;
    $tmp =~ s!\x00! !g;
    $line .= "$tmp";
  }

  if (defined $ja_kun) {
    $tmp = $ja_kun;
    $tmp =~ s!\x00! !g;
    $line .= "$tmp";
  }

  if (defined $nanori) {
    $tmp = $nanori;
    $tmp =~ s!\x00! !g;
    $line .= "T1 $tmp";
  }

  if (defined $radical_names) {
    $tmp = $radical_names;
    $tmp =~ s!\x00! !g;
    $line .= "T2 $tmp";
  }

  foreach my $m (split '\x00', $meaning) {
    $line .= "{$m} ";
  }

  $line =~ s/ $//;

  print OUT "$line\n";

  # only JIS X 0208 kanji (hack!)
  exit if hex($jis208) >= 0x7426;

  $twig->purge;
}


sub process_header {
  my ($twig, $header) = @_;

  my ($fver, $dver, $date, $string);


  if (defined ($fver = ($header->descendants("file_version"))[0] ) ) {
    $fver = $fver->first_child->trimmed_text;
  }

  if (defined ($dver = ($header->descendants("database_version"))[0] ) ) {
    $dver = $dver->first_child->trimmed_text;
  }

  if (defined ($date = ($header->descendants("date_of_creation"))[0] ) ) {
    $date = $date->first_child->trimmed_text;
  }

  $string = "# KANJIDIC $date/${dver}_$fver Copyright (C) 2004 James William Breen. See the kanjidic_doc.html file for full details. Enquiries: jwb\@csse.monash.edu.au";

  print OUT "$string\n";

  $twig->purge;
}

# simple kuten to JIS conversion
# works only for XX-YY, no error checking!

sub kuten2jis {
  my ($ku, $ten) = split '-', shift;

  $ku = $ku + 0x20;
  $ten = $ten + 0x20;

  return sprintf("%02X%02X", $ku, $ten);
}
