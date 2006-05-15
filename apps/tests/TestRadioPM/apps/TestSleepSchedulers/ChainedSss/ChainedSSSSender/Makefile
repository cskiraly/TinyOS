BASE = $(TOSROOT)/apps/tests/TestRadioPM/apps

COMPONENT=ChainedSSSSenderAppC

BUILD_EXTRA_DEPS += DelayChainedMsgs.class PrintDelayChainedMsgs.class

%.class: %.java
	javac $<

DelayChainedMsgs.java: $(BASE)/TestSleepSchedulers/SenderAddr.h
	mig java -target=$(PLATFORM) $(CFLAGS) -java-classname=DelayChainedMsgs $(BASE)/TestSleepSchedulers/SenderAddr.h DelayChainedMsgs -o $@

CFLAGS += -I$(BASE)/../apps/TestSleepSchedulers
include $(BASE)/TestSleepSchedulers/MakeIncludes	

include $(MAKERULES)


