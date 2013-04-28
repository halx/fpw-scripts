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
use File::Basename;
use Time::localtime;
use Try::Tiny;

use lib "$HOME/usr/lib/perl5";
use lib "$HOME/usr/lib/perl5/site_perl";



my %dictionaries = (
    'JMdict' => {
	'DICT_LANG' => [
	    'eng',
	    'dut',
	    # 'fra',
	    # 'rus'
	    ]
    },

    'kanjidic' => {
	'DICT_LANG' => [
	    'en',
	    # 'es',
	    # 'fr',
	    # 'pt'
	    ]
    },
    
    'jp_examples' => {
	'SHORT' => [0, 1]
    },

    'JMnedict' => undef
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


sub dict_clean {
    print "... cleaning distribution ...\n";
    return system("$fpwmake distclean");
}

sub dict_build {
    print "... creating distribution ...\n";
    return system("$fpwmake create-distrib");
}



### main

my $top_dir = dirname(abs_path($0));
chdir $top_dir;

my ($date, $lang, $error);

foreach my $dictionary (keys %dictionaries) {
    $date = ctime();

    print "        ========== START $dictionary($lang) $date ==========\n";

    chdir $dictionary;
    dict_clean();

    if (defined $dictionaries{$dictionary}) {
	foreach my $env (keys $dictionaries{$dictionary}) {
	    foreach $lang (@{$dictionaries{$dictionary}{$env}}) {
		$ENV{$env} = $lang;
		$error = dict_build();
	    }

	    print "\n";
	}
    } else {
	$error = dict_build();
    }

    $date = ctime();
    
    if (not $error) {
	print "        ========== END   $dictionary($lang) $date ==========\n\n";
    } else {
	print "        !!!!!!!!!! ERROR $dictionary($lang) $date !!!!!!!!!!\n\n";
    }

    chdir $top_dir;
}