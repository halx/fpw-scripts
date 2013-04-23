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



### parameters that may need to be adapted: DICT_LANG, ROMAJI, INSTALLDIR

# "eng" (english), "fre" (french), "ger" (german), "rus" (russian),
# "dut" (dutch), and "nor" (norwegian) supported (some may have only a few
# entries)
ifndef DICT_LANG
DICT_LANG = eng
endif

# romaji search keys if > 0
ROMAJI = 1

# install directory
#INSTALLDIR = /usr/local/share/dict  # default


### leave unchanged

DEBUG = 0			# give more feedback





# version information
SCRIPT_VERSION = 2.6.1
# we need to get the following automatically somehow...
JMDICT_VERSION = "JMdict(${DICT_LANG}) ${TODAY} (DTD v1.07), conversion script v${SCRIPT_VERSION}"

NAME = JMdict
PACKAGE = ${NAME}-fpw${SCRIPT_VERSION}

# input data
INPUTS_DIR = data
JMDICT = ${NAME}.gz
SOURCES = ${INPUTS_DIR}/${JMDICT}
README_FILE = README
README_TMPL_FILE = ${INPUTS_DIR}/README.tmpl
INFO_FILE = ${INPUTS_DIR}/INFO
GAIJI_FILE = gaiji/gaiji_table
CATALOGS_TXT_FILE = catalogs.txt

# installation file names and directories:

ifneq (${DICT_LANG},rus)
ifeq (${DICT_LANG},eng)
    LNG = en
endif
ifeq (${DICT_LANG},fre)
    LNG = fr
endif
ifeq (${DICT_LANG},ger)
    LNG = de
endif
ifeq (${DICT_LANG},nor)
    LNG = no
endif
ifeq (${DICT_LANG},dut)
    LNG = nl
endif
  DIR = ${NAME}_${DICT_LANG}_${TODAY}
  COPYRIGHT_FILE = ${INPUTS_DIR}/License
  DISTRIB = edict_${LNG}.fpw.tar.gz
  DISTRIB_EBZIP = edict_${LNG}.fpwebz.tar
else
  DIR = jr-edict
  COPYRIGHT_FILE = ${INPUTS_DIR}/License.jr
  DISTRIB = ${DIR}.fpw.tar.gz
  DISTRIB_EBZIP = ${DIR}.fpwebz.tar
endif

DIR2 = ${NAME}
INSTALLDIR2 = ${INSTALLDIR}/${DIR}

DATA_DIR = DATA
GAIJI_DIR = GAIJI

GAIJI_UC = 1

CATALOGS = CATALOGS
HONMON = HONMON

#
HALFCHARS = gaiji/halfchar.txt

PACKAGEEXTRA = ${README_FILE} ChangeLog ${INFO_FILE}=INFO ${COPYRIGHT_FILE}=License
ARCHIVEEXTRA = AUTHORS COPYING ChangeLog catalogs.txt.tmpl ${INFO_FILE} ${README_TMPL_FILE} ${INPUTS_DIR}/License ${INPUTS_DIR}/License.jr
CLEANEXTRA = gai16h err ${README_FILE} ${CATALOGS_TXT_FILE}
DISTCLEANEXTRA = ${SOURCES}

FPWPARSERFLAGS = --language=${DICT_LANG} --romaji-key=${ROMAJI}\
		 --data-file=${SOURCES} --info-file=${INFO_FILE} \
		 --readme-file=${README_FILE} --copyright-file=${COPYRIGHT_FILE} \
		 --gaiji-file=${GAIJI_FILE} --version-string=${JMDICT_VERSION} \
		 --debug=${DEBUG}

# additional targets
ALLDEPS = ${README_FILE} ${CATALOGS_TXT_FILE}


.SUFFIXES:

include ${FPWING_SHARE}/fpwutils.mk  # master makefile
#include ${prefix}/src/fpw-scripts/Make-common
include ../Make-common

${README_FILE}: ${README_TMPL_FILE}
	sed -e s/%VERSION%/${JMDICT_VERSION}/ $< > $@

${CATALOGS_TXT_FILE}: ${CATALOGS_TXT_FILE}.tmpl
	sed -e s/%DIR2%/${DIR2}/ $< > $@

${SOURCES}:
	cd ${INPUTS_DIR}; \
	${DOWNLOAD} ${FTP_SERVER}/${JMDICT} ${DOWNLOAD_DEST}
