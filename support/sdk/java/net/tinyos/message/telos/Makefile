
TOS = $(shell ncc -print-tosdir)
PACKAGE = net.tinyos.message
MIG = mig java

AM=$(TOS)/types/AM.h
TOSMsg=$(TOS)/lib/serial/Serial.h

MSGS = SerialAMPacket.java
INITIAL_TARGETS = $(MSGS)
OTHER_CLEAN = cleanmig

ROOT = ../../../..
include $(ROOT)/Makefile.include

SerialAMPacket.java: $(TOSMsg)
	$(MIG) -target=telosb -java-classname=$(PACKAGE).telos.SerialAMPacket  $(TOSMsg) serial_packet -o $@

cleanmig:
	rm -f $(MSGS)
