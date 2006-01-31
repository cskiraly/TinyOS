
TOS = $(shell ncc -print-tosdir)
PACKAGE = net.tinyos.message
MIG = mig java

SerialAMPacket=$(TOS)/lib/serial/Serial.h

MSGS = SerialAMPacket.java
INITIAL_TARGETS = $(MSGS)
OTHER_CLEAN = cleanmig

ROOT = ../../../..
include $(ROOT)/Makefile.include

SerialAMPacket.java: $(TOSMsg)
	$(MIG) -target=eyesIFXv2 -java-classname=$(PACKAGE).eyesIFX.SerialAMPacket  $(SerialAMPacket) serial_packet -o $@

cleanmig:
	rm -f $(MSGS)
