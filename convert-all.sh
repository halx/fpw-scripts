#!/bin/bash
#
# Copyright (C) 2010-2013 Hannes Loeffler
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



# perlbrew Perl
if [ -f ~/perl5/perlbrew/etc/bashrc ]; then
  . ~/perl5/perlbrew/etc/bashrc
fi

# dictionary and language selection
dictionaries="JMnedict JMdict jp_examples kanjidic"

#JMdict_lang="eng dut fre rus"
JMdict_lang="eng dut"

#kanjidic_lang="en es fr pt"
kanjidic_lang="en"


### functions

# prepend a variable with a value if it exists, otherwise create it with the
# value
# export the variable
prepend_path () {
    if [ -z "$1" -o -z "$2" ]; then
	echo "Usage: prepend_env var_name value" 1>&2;
	exit 1
    fi

    name=$1
    to=$2

    for dir in $(echo $to | tr ':' ' '); do
	case "${!name}" in
	    $dir:*|*:$dir)
                ;;
            *)
	        if [ -z "${!name}" ]; then
		    export $name="$dir"
		else
		    export $name="$dir":${!name}
		fi
        esac
    done
}

# change to script's directory
setwd () {
  local p=$(dirname $0)

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


# the FreePWING make utility
prefix=$HOME/usr
fpwmake=$prefix/bin/fpwmake

# final destination
export dict_home=$HOME/dicts

# make sure these environment variables are set correctly
export FPWING_SHARE=$prefix/share/freepwing
export LANG=C

prepend_path PATH $HOME/usr/bin
prepend_path PERL5LIB $HOME/usr/lib/perl5/site_perl:$HOME/usr/lib/perl5


### main

# change to work directory
setwd

# build dictionaries in selected languages
for dictionary in $dictionaries; do
    date=$(date)
    echo "          ========== START $dictionary $date =========="

    (
	cd $dictionary
	. ./convert.sh   # subscript will see all variables when sourced
    )

    err=$?
    date=$(date)

    if [ 0 -eq $err ]; then
	echo "          ========== END   $dictionary $date =========="
	echo
    else
	echo "          !!!!!!!!!! ERROR $dictionary $date !!!!!!!!!!"
	echo
    fi
done
