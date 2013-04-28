#!/usr/bin/env perl
#
# Copyright (C) 2013 Hannes Loeffler
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
# create-all.pl: simple script to create FreePWing conversions of Jim Breen's
#                JMdict, JMnedict, Kanjidic and Japanese example sentences
#                the script will create the tar archives of the dictionaries
#



use strict;

use Env qw(HOME PATH);
use Cwd qw(abs_path getcwd);
use Time::localtime;

use lib "$HOME/usr/lib/perl5";
use lib "$HOME/usr/lib/perl5/site_perl";


my @dictionaries = (
  'JMnedict',
  'JMdict',
  'jp_examples',
  'kanjidic'
);

my @JMdict_lang = (
  'eng',
  'dut',
# 'fre',
# 'rus'
);

my @kanjidic_lang = (
  'en',
# 'es',
# 'fr',
# 'pt'
);

my $prefix = "$HOME/usr";

# the FreePWING make utility
my $fpwmake = "$prefix/bin/fpwmake";

# final destination
$ENV{'dict_home'} = "$HOME/dicts";

# make sure these environment variables are set correctly
$ENV{'FPWING_SHARE'} = "$prefix/share/freepwing";
$ENV{'LANG'} = 'C';

$ENV{'PATH'} = prepend_path($ENV{'PATH'}, "$HOME/usr/bin");
$ENV{'LD_LIBRARY_PATH'} =
  prepend_path($ENV{'LD_LIBRARY_PATH'}, "$HOME/usr/lib");


### helper functions

sub prepend_path {
  my $path = shift;
  my $add = shift;

  if ($path eq "") {
    $path = $add;
  } else {
    if ($add ne (split(':', $path))[0] ) { 
      $path = "$add:$path";
    }
  }

  return $path;
}


sub buildall {
  my $error = 0;

  print "...cleaning distribution...\n";
  $error = system("$fpwmake distclean");

  print "...creating distribution...\n";
  $error = system("$fpwmake create-distrib");
  exit $error if $error;

  print "...cleaning distribution...\n";
  $error = system("$fpwmake distclean");
}



### main

my $top_dir = abs_path($0);
chdir $top_dir;

my ($date);

foreach my $dictionary (@dictionaries) {
  $date = ctime();

  print "          ========== START $dictionary $date ==========\n";

  chdir $dictionary;
  require 'convert.pl';
  chdir $top_dir;

  $date = ctime();
}
