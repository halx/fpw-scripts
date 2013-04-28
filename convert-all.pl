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
use File::Basename qw(dirname);
use Time::localtime qw(ctime);

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


sub final_message {
    my $dictionary = shift;
    my $error = shift;
    my $lang = shift;

    my $date = ctime();


    $lang = '(' . $lang . ')';

    if (not $error){
	print "        ========== END   $dictionary$lang $date ==========\n\n";
    } else {
	print "        !!!!!!!!!! ERROR $dictionary$lang $date !!!!!!!!!!\n\n";
    }
}


### main

my $top_dir = dirname(abs_path($0));

if (not chdir($top_dir) ) {
    print "!!! Error: can't cd to $top_dir\n";
    exit 1;
}

my ($date, $lang, $error);

foreach my $dictionary (keys %dictionaries) {
    if (not chdir($dictionary) ) {
	print "!!! Error: can't cd to $dictionary\n";
	next;
    }

    $date = ctime();
    dict_distclean();

    if (defined $dictionaries{$dictionary}) {
	foreach my $env (keys $dictionaries{$dictionary}) {
	    foreach $lang (@{$dictionaries{$dictionary}{$env}}) {
		print "        ========== START $dictionary $date ==========\n";
		
		dict_clean();
		
		$ENV{$env} = $lang;
		$error = dict_build();

		final_message($dictionary, $error, $lang);
	    }
	}
    } else {
	print "        ========== START $dictionary $date ==========\n";
	
	$error = dict_build();

	final_message($dictionary, $error, '');
    }

    dict_distclean();
    chdir $top_dir;
}
