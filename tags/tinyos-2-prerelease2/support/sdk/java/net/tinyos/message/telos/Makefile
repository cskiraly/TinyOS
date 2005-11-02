
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
	$(MIG) -target=telos -java-classname=$(PACKAGE).telos.message_t  $(TOSMsg) message_t -o $@

ActiveMsg.java: $(AM)
	$(MIG) -target=telos -java-classname=$(PACKAGE).telos.ActiveMsg  $(AM) ActiveMsg -o $@

cleanmig:
	rm -f $(MSGS)
