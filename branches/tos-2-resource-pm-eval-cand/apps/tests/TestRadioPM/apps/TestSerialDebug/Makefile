BASE_DIR = $(TOSROOT)/apps/tests/TestRadioPM/lib/

COMPONENT=TestSerialDebugAppC

CFLAGS += -I$(BASE_DIR)/serialDebug
BUILD_EXTRA_DEPS += SerialDebugMsg.class PrintSerialDebugMsgs.class

%.class: %.java
	javac $<

SerialDebugMsg.java: $(BASE_DIR)/serialDebug/SerialDebugMsg.h
	mig java -target=$(PLATFORM) $(CFLAGS) -java-classname=SerialDebugMsg $(BASE_DIR)/serialDebug/SerialDebugMsg.h SerialDebugMsg -o $@

include $(MAKERULES)

