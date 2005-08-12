
TOS = $(shell ncc -print-tosdir)
PACKAGE = net.tinyos.message
MIG = mig java

TOSMsg=$(TOS)/lib/serial/Serial.h

MSGS = SerialAMPacket.java
INITIAL_TARGETS = $(MSGS)
OTHER_CLEAN = cleanmig

ROOT = ../../../..
include $(ROOT)/Makefile.include

SerialAMPacket.java: $(TOSMsg)
	$(MIG) -target=mica2 -java-classname=$(PACKAGE).avrmote.SerialAMPacket  $(TOSMsg) SerialAMPacket -o $@

cleanmig:
	rm -f $(MSGS)
