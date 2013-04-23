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



### user definable variables

# "en", "de", "es", "fr", or "pt"
ifndef DICT_LANG
  DICT_LANG = en
endif

# use gaiji for umlauts and accents, otherwise use ASCII equivalents
GAIJI = 1

# add chinese and korean readings to output
ADDCK = 1

# show all codes in output
PRINTCODES = 1

# show radicals in output
PRINTRADS = 1

# add codes to search keys (some are ALWAYS added, see code)
KEYCODES = 1

# add radicals to search keys
KEYRADS = 1

# add large kanji bitmaps
LARGEBMP = 1


### leave unchanged

DEBUG = 0

SCRIPT_VERSION = 1.7.4
NAME = kanjidic
PACKAGE = ${NAME}-fpw${SCRIPT_VERSION}

# input data
INPUTS_DIR = data
README_FILE = ${INPUTS_DIR}/README
INFO_FILE = ${INPUTS_DIR}/${NAME}.doc
COPYRIGHT_FILE = ${INPUTS_DIR}/License
RADK_FILE = ${INPUTS_DIR}/radkfile.gz
CRADK_FILE = ${INPUTS_DIR}/classical_radicals
GAIJI_FILE = gaiji/gaiji_table
CATALOGS_TXT_FILE = catalogs.txt

ifeq (${DICT_LANG},en)
  KANJIDIC = ${NAME}.gz
  TITLE = "\xb4\xc1\xb1\xd1\xbb\xfa\xc5\xb5"
  HANGAIJI = ""
else
  KANJIDIC = ${NAME}_${DICT_LANG}.gz
  HANGAIJI = "HanGaiji   = \"gai16h\""
endif

ifeq (${DICT_LANG},de)
  TITLE = "\xb4\xc1\xc6\xc8\xbb\xfa\xc5\xb5"
endif

ifeq (${DICT_LANG},es)
  TITLE = "\xb4\xc1\xc0\xbe\xbb\xfa\xc5\xb5"
endif

ifeq (${DICT_LANG},fr)
  TITLE = "\xb4\xc1\xca\xa9\xbb\xfa\xc5\xb5"
endif

ifeq (${DICT_LANG},pt)
  TITLE = "\xb4\xc1\xc9\xf2\xbb\xfa\xc5\xb5"
endif

SOURCES = ${INPUTS_DIR}/${KANJIDIC}

# installation file names and directories:
DIR = ${NAME}_${DICT_LANG}_${TODAY}
DIR2 = ${NAME}
INSTALLDIR2 = ${INSTALLDIR}/${DIR}
DATA_DIR = DATA
GAIJI_DIR = GAIJI

GAIJI_UC = 1

CATALOGS = CATALOGS
HONMON = HONMON

DISTRIB = ${NAME}_${DICT_LANG}.fpw.tar.gz
DISTRIB_EBZIP = ${NAME}_${DICT_LANG}.fpwebz.tar

#
ifeq (${GAIJI},1)
  ifneq (${DICT_LANG},en)
    HALFCHARS = gaiji/halfchar.txt
  endif
endif

FULLCHARS = gaiji/fullchar.txt

ifeq (${LARGEBMP},1)
  CGRAPHS = images/kanjibmp.txt
endif

PACKAGEEXTRA = ${INFO_FILE}=INFO ${README_FILE}=README ${COPYRIGHT_FILE}=License ChangeLog
ARCHIVEEXTRA = ${INFO_FILE} ${README_FILE} ${COPYRIGHT_FILE} AUTHORS COPYING ChangeLog \
	       gaiji images
CLEANEXTRA = gai16h gai16f log ${CATALOGS_TXT_FILE} ${README_FILE}
DISTCLEANEXTRA = ${SOURCES}

FPWPARSERFLAGS =  --language=${DICT_LANG} --gaiji=${GAIJI} \
		  --data-file=${SOURCES} --info-file=${INFO_FILE} \
		  --readme-file=${README_FILE} --copyright-file=${COPYRIGHT_FILE} \
		  --gaiji-file=${GAIJI_FILE} --radical-file=${RADK_FILE} \
		  --classical-radical-file=${CRADK_FILE} \
		  --add-CK=${ADDCK} --print-codes=${PRINTCODES} \
		  --print-radicals=${PRINTRADS} --key-codes=${KEYCODES} \
		  --key-radicals=${KEYRADS} --large-kanji-bitmaps=${LARGEBMP}\
		  --debug=${DEBUG}

ALLDEPS = ${SOURCES} ${RADK_FILE} ${README_FILE} ${CATALOGS_TXT_FILE}

.SUFFIXES:

include ${FPWING_SHARE}/fpwutils.mk
include ../Make-common

${README_FILE} : ${README_FILE}.in
	sed -e s/@VERSION@/${SCRIPT_VERSION}/ $< > $@

${CATALOGS_TXT_FILE}: ${CATALOGS_TXT_FILE}.tmpl
	sed -e s/%TITLE%/${TITLE}/ \
	    -e s/%DIR2%/${DIR2}/ \
	    -e s/%HAN%/${HANGAIJI}/ $< > $@

${SOURCES}:
	cd ${INPUTS_DIR}; \
	${DOWNLOAD} ${FTP_SERVER}/${KANJIDIC} ${DOWNLOAD_DEST}

${RADK_FILE}:
	cd ${INPUTS_DIR}; \
	${DOWNLOAD} ${FTP_SERVER}/$(notdir $@ ${DOWNLOAD_DEST})
