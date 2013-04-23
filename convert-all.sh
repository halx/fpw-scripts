#!/bin/bash
#
# Copyright (C) 2010 Hannes Loeffler
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
# create-all.sh: simple script to create FreePWing conversions of Jim Breen's
#                JMdict, JMnedict, Kanjidic and Japanese example sentences
#                the script will create the tar archives of the dictionaries
#



if [ -f ~/perl5/perlbrew/etc/bashrc ]; then
  . ~/perl5/perlbrew/etc/bashrc
fi

# dictionary and language selection
dictionaries="JMnedict JMdict jp_examples kanjidic"
JMdict_lang="eng dut"
#JMdict_lang="eng dut fre rus"
kanjidic_lang="en"
#kanjidic_lang="en es fr pt"

# the FreePWING make utility
prefix=$HOME/usr
fpwmake=$prefix/bin/fpwmake

# final destination
export dict_home=$HOME/dicts

# make sure these environment variables are set correctly
export FPWING_SHARE=$prefix/share/freepwing
export LANG=C
export PATH=$HOME/usr/bin:$PATH
#export PERL5LIB=$HOME/usr/lib/perl5/5.12.2:$HOME/usr/lib/perl5/site_perl/5.12.2:$PERL5LIB
export PERL5LIB=$HOME/usr/share/perl:$HOME/usr/lib/perl5/site_perl:$HOME/usr/lib/perl5:$HOME/usr/lib/perl


### functions

# change to script's directory
setwd () {
  local p=`dirname $0`

  cd $p
}

# build all targets
buildall () {
  $fpwmake distclean

  # create tar archives and copy them to $dict_home
  $fpwmake create-distrib
  err=$?
  [ 0 -ne $err ] && exit $err

  $fpwmake distclean
}


### main

# change to work directory
setwd

# build dictionaries in selected languages
for dictionary in $dictionaries; do
  date=`date`
  echo "          ========== START $dictionary $date =========="

  (
    cd $dictionary
    . ./convert.sh   # subscript will see all variables when sourced
  )

  err=$?
  date=`date`

  if [ 0 -eq $err ]; then
    echo "          ========== END   $dictionary $date =========="
    echo
  else
    echo "          !!!!!!!!!! ERROR $dictionary $date !!!!!!!!!!"
    echo
  fi
done
