# $Id: Makefile,v 1.1.2.1 2005-05-23 22:12:49 idgay Exp $
#
# TinyOS Tools Makefile
#
# @author  TinyOS Team
#

TOS = $(shell ncc -print-tosdir)
PACKAGE = net.tinyos.tools

MIG = mig java
NCG = ncg java

MSGS = DelugeConsts.java DelugeAdvMsg.java DelugeReqMsg.java DelugeDataMsg.java SimpleCmdMsg.java LogMsg.java

INITIAL_TARGETS = $(MSGS)

OTHER_CLEAN = cleanmig

ROOT = ../../..
include $(ROOT)/Makefile.include

#
# Deluge
#

DELUGE_PLATFORM=pc
DELUGE_LIB=$(TOS)/lib/Deluge
TOSBOOT_LIB=$(TOS)/lib/Deluge/TOSBoot/include

DelugeAdvMsg.java:
	$(MIG) -java-classname=$(PACKAGE).DelugeAdvMsg $(DELUGE_LIB)/DelugeMsgs.h DelugeAdvMsg -o $@

DelugeReqMsg.java:
	$(MIG) -java-classname=$(PACKAGE).DelugeReqMsg $(DELUGE_LIB)/DelugeMsgs.h DelugeReqMsg -o $@

DelugeDataMsg.java:
	$(MIG) -java-classname=$(PACKAGE).DelugeDataMsg $(DELUGE_LIB)/DelugeMsgs.h DelugeDataMsg -o $@

DelugeConsts.java:
	$(NCG) -java-classname=$(PACKAGE).DelugeConsts -target=$(DELUGE_PLATFORM) -I$(DELUGE_LIB) -I$(TOSBOOT_LIB) $(DELUGE_LIB)/DelugeC.nc Deluge.h DelugePageTransfer.h DelugeStableStore.h DelugeMsgs.h -o $@

#
# SimpleCmd
#

SIMPLECMD_LIB=$(TOS)/../apps/SimpleCmd

SimpleCmdMsg.java:
	$(MIG) -java-classname=$(PACKAGE).SimpleCmdMsg $(SIMPLECMD_LIB)/SimpleCmdMsg.h SimpleCmdMsg -o $@

LogMsg.java:
	$(MIG) -java-classname=$(PACKAGE).LogMsg $(SIMPLECMD_LIB)/SimpleCmdMsg.h LogMsg -o $@

#
# Clean
#

cleanmig:
	rm -f $(MSGS)
