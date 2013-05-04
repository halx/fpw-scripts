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
use Cwd qw(abs_path);
use File::Basename qw(dirname);
use Time::localtime qw(ctime);


my @dictionaries = (
  make_dict(
    'JMdict',
    (
     'eng',
     'dut',
     #'fra',
     #'rus'
    )
  ),
  make_dict(
    'JMnedict',
    undef    
  ),
  make_dict(
    'kanjidic',
    (
     'en',
     #'es',
     #'fr',
     #'pt'
    )
  ),
  make_dict(
    'jp_examples',
    ('long', 'short')
  )
);

my $prefix = "$HOME/usr";

# the FreePWING make utility
my $fpwmake = "$prefix/bin/fpwmake";

# final destination
$ENV{'dict_home'} = "$HOME/dicts";

# make sure these environment variables are set correctly
$ENV{'FPWING_SHARE'} = "$prefix/share/freepwing";
$ENV{'LANG'} = 'C';

$ENV{'PATH'} = prepend_path($ENV{'PATH'}, "$prefix/bin");
$ENV{'LD_LIBRARY_PATH'} =
  prepend_path($ENV{'LD_LIBRARY_PATH'}, "$prefix/lib");


### main

my $top_dir = dirname(abs_path($0));

foreach my $dictionary (@dictionaries) {
  if (not chdir($top_dir) ) {
    print "!!! Error: can't cd to $dictionary\n";
    next;
  }

  $dictionary->();

  chdir $top_dir;
}


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


sub make_dict {
  my $name = shift;
  my @variants = @_;

  return sub {
    my $error;

    if (not chdir($name) ) {
      print "!!! Error: can't cd to $name\n";
      next;
    }
	
    my $date = ctime();

    dict_distclean();

    foreach my $variant (@variants) {
      dict_clean();

      # hard-coded environment variable for Makefiles!
      $ENV{'VARIANT'} = $variant;

      print "        ========== START $name";
      print "($variant)" if $variant;
      print " $date ==========\n";

      $error = dict_build();

      unless ($error) {
	print "        ========== END   $name";
	print "($variant)" if $variant;
	print " $date ==========\n";
      } else {
	print "        !!!!!!!!!! ERROR $name";
	print "($variant)" if $variant;
	print " $date !!!!!!!!!!\n";	    }
    }

    dict_distclean();
  }
}


sub dict_clean {
    print "... fpwmake clean ...\n";
    return system("$fpwmake clean");
}

sub dict_distclean {
    print "... fpwmake distclean ...\n";
    return system("$fpwmake distclean");
}

sub dict_build {
    print "... fpwmake create-distrib ...\n";
    return system("$fpwmake create-distrib");
}
