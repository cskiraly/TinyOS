BASE = $(TOSROOT)/apps/tests/TestRadioPM/apps

COMPONENT=GenericReceiverAppC
CFLAGS += -I%T/lib/oski -I../

BUILD_EXTRA_DEPS += NumSenderMsgs.class PrintNumSenderMsgs.class

%.class: %.java
	javac $<

NumSenderMsgs.java: $(BASE)/TestSleepSchedulers/SenderAddr.h
	mig java -target=$(PLATFORM) $(CFLAGS) -java-classname=NumSenderMsgs $(BASE)/TestSleepSchedulers/SenderAddr.h NumSenderMsgs -o $@

CFLAGS += -I$(BASE)/../apps/TestSleepSchedulers
include $(BASE)/TestSleepSchedulers/MakeIncludes	

include $(MAKERULES)

