
TOS = $(shell ncc -print-tosdir)
PACKAGE = net.tinyos.message
MIG = mig java

AM=$(TOS)/types/AM.h
TOSMsg=$(TOS)/types/TOSMsg.h

MSGS = message_t.java ActiveMsg.java
INITIAL_TARGETS = $(MSGS)
OTHER_CLEAN = cleanmig

ROOT = ../../../..
include $(ROOT)/Makefile.include

message_t.java: $(TOSMsg)
	$(MIG) -target=mica2 -java-classname=$(PACKAGE).avrmote.message_t  $(TOSMsg) message_t -o $@

ActiveMsg.java: $(AM)
	$(MIG) -target=mica2 -java-classname=$(PACKAGE).avrmote.ActiveMsg  $(AM) ActiveMsg -o $@

cleanmig:
	rm -f $(MSGS)
