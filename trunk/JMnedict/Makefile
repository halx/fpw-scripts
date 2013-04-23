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

# install directory
#INSTALLDIR = /usr/local/share/dict


### leave unchanged

DEBUG = 0

SCRIPT_VERSION = 1.4.0
NAME = JMnedict
PACKAGE = ${NAME}-fpw${SCRIPT_VERSION}

# input data
INPUTS_DIR = data
JMNEDICT = ${NAME}.xml.gz
SOURCES = ${INPUTS_DIR}/${JMNEDICT}
README_FILE = ${INPUTS_DIR}/README
INFO_FILE = ${INPUTS_DIR}/INFO
COPYRIGHT_FILE = ${INPUTS_DIR}/License
GAIJI_FILE = gaiji/gaiji_table

# installation file names and directories:
DIR = ${NAME}_${TODAY}
DIR2 = ${NAME}
INSTALLDIR2 = ${INSTALLDIR}/${DIR}
DATA_DIR = DATA
GAIJI_DIR = GAIJI

GAIJI_UC = 1

CATALOGS = CATALOGS
HONMON = HONMON

DISTRIB = ${NAME}.fpw.tar.gz
DISTRIB_EBZIP = ${NAME}.fpwebz.tar

#
HALFCHARS = gaiji/halfchar.txt

PACKAGEEXTRA = ${INFO_FILE}=INFO ${README_FILE}=README ${COPYRIGHT_FILE}=License ChangeLog
ARCHIVEEXTRA = ${INFO_FILE} ${README_FILE} ${COPYRIGHT_FILE} AUTHORS COPYING ChangeLog
CLEANEXTRA = gai16h log err
DISTCLEANEXTRA = ${SOURCES}

FPWPARSERFLAGS = --data-file=${SOURCES} --info-file=${INFO_FILE} \
                 --readme-file=${README_FILE} --copyright-file=${COPYRIGHT_FILE} \
                 --gaiji-file=${GAIJI_FILE} --debug=${DEBUG}

.SUFFIXES:

include ${FPWING_SHARE}/fpwutils.mk
include ../Make-common

${SOURCES}:
	cd ${INPUTS_DIR}; \
	${DOWNLOAD} ${FTP_SERVER}/${JMNEDICT} ${DOWNLOAD_DEST}
