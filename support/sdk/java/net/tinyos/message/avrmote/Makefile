
TOS = $(shell ncc -print-tosdir)
PACKAGE = net.tinyos.message
MIG = mig java

TOSMsg=$(TOS)/types/TOSMsg.h

MSGS = message_t.java
INITIAL_TARGETS = $(MSGS)
OTHER_CLEAN = cleanmig

ROOT = ../../../..
include $(ROOT)/Makefile.include

message_t.java: $(TOSMsg)
	$(MIG) -target=mica2 -java-classname=$(PACKAGE).avrmote.message_t  $(TOSMsg) message_t -o $@

cleanmig:
	rm -f $(MSGS)
