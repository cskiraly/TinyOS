#!/bin/sh
# Copyright (c) 2005 Intel Corporation
# All rights reserved.
#
# This file is distributed under the terms in the attached INTEL-LICENSE     
# file. If you do not find these files, copies can be found by writing to
# Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
# 94704.  Attention:  Intel License Inquiry.

dnl -*- m4 -*-

# force autoconf 2.5 on Debian systems
AC_PREREQ(2.50)

AC_INIT(tinyos-tools, 1.2pre1)
AC_CONFIG_AUX_DIR(config-aux)
AM_INIT_AUTOMAKE

AC_PROG_CC
AC_PROG_RANLIB

if test -z "$NESCC_PREFIX"; then
  AC_PATH_PROG(pathnescc, nescc)
  if test -z "$pathnescc"; then
    AC_MSG_ERROR(I can't find nescc)
  else
    NESCC_PREFIX=`dirname $pathnescc`
    NESCC_PREFIX=`dirname $NESCC_PREFIX`
  fi
fi
nescc_prefix=`(cd $NESCC_PREFIX;pwd)`
AC_SUBST(nescc_prefix)


AC_PATH_PROG(pathperl, perl)
if test -z "$pathperl" ; then
  AC_MSG_ERROR(I can't find perl); 
fi

if test -z "$DEFAULT_TARGET"; then
  DEFAULT_TARGET=mica
fi
default_target=$DEFAULT_TARGET
AC_MSG_NOTICE(Default ncc build target is $default_target)
AC_SUBST(default_target)

if test -z "$TOSDIR"; then
  if test -d ../tos; then
    TOSDIR=../tos
  elif test -d ../../tos; then
    TOSDIR=../../tos
  elif test -d $HOME/nest/tos; then
    TOSDIR=$HOME/nest/tos
  else
    AC_MSG_ERROR(I can't find the tos directory);
  fi
fi
TOSDIR=`(cd $TOSDIR;pwd)`
AC_MSG_NOTICE(TinyOS directory is $TOSDIR)
AC_SUBST(TOSDIR)

GETENVLIB=libgetenv.so
JDK=/opt/IBMJava2-141
AC_SUBST(GETENVLIB)
AC_SUBST(JDK)

AC_CONFIG_SUBDIRS(platforms/mica/uisp)

AC_OUTPUT(
	Makefile
	platforms/Makefile
	platforms/mica/Makefile
	platforms/mica/cc1000-channelgen/Makefile
	platforms/msp430/Makefile
	tinyos/Makefile
	tinyos/java/Makefile
	tinyos/java/env/Makefile
	tinyos/misc/Makefile
	tinyos/ncc/Makefile
	tinyos/ncc/mig
	tinyos/ncc/ncc
	tinyos/ncc/ncg
	tinyos/ncc/nesdoc
)
