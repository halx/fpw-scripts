#
# Copyright (C) 2004-2010 Hannes Loeffler
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



### parameters that may need to be adapted: SHORT, PRUNE, INSTALLDIR

# short or long version
#SHORT = 1

# prune data, i.e. remove obvious duplicates
PRUNE = 1

# install directory
#INSTALLDIR = /usr/local/share/dict


### leave unchanged

DEBUG = 0

SCRIPT_VERSION = 1.4.0
NAME = jp_examples
PACKAGE = ${NAME}-fpw${SCRIPT_VERSION}

# input data
INPUTS_DIR = data

ifeq (${SHORT},1)
  EXT = _s
else
  EXT =
endif

EXAMPLES = examples${EXT}.gz
SOURCES = ${INPUTS_DIR}/${EXAMPLES}
READ_ME_FILE = ${INPUTS_DIR}/README${EXT}

# installation file names and directories:
DIR = ${NAME}${EXT}_${TODAY}
DIR2 = examples
INSTALLDIR2 = ${INSTALLDIR}/${DIR}
DATA_DIR = DATA
GAIJI_DIR = GAIJI

GAIJI_UC = 1

CATALOGS = CATALOGS
HONMON = HONMON

DISTRIB = ${NAME}${EXT}.fpw.tar.gz
DISTRIB_EBZIP = ${NAME}${EXT}.fpwebz.tar


PACKAGEEXTRA = ${READ_ME_FILE}=README ChangeLog
ARCHIVEEXTRA = ${READ_ME_FILE}=README AUTHORS COPYING ChangeLog
CLEANEXTRA = log
DISTCLEANEXTRA = ${SOURCES}

FPWPARSERFLAGS = --data-file=${SOURCES} --readme-file=${READ_ME_FILE} \
		 --prune=${PRUNE} --debug=${DEBUG}


.SUFFIXES:

include ${FPWING_SHARE}/fpwutils.mk  # master makefile
include ../Make-common

${SOURCES}:
	cd ${INPUTS_DIR}; \
	${DOWNLOAD} ${FTP_SERVER}/${EXAMPLES} ${DOWNLOAD_DEST}
