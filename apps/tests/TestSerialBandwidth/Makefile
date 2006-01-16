COMPONENT=TestSerialAppC
CFLAGS += -I%T/lib/oski
BUILD_EXTRA_DEPS += TestSerialMsg.class TestSerial.class
CFLAGS += -DDEFAULT_BAUDRATE=57600
#CFLAGS += -DDEFAULT_BAUDRATE=115200
#CFLAGS += -DDEFAULT_BAUDRATE=230400
CFLAGS += -DTOSH_DATA_LENGTH=100

%.class: %.java
	javac $<

TestSerialMsg.java:
	mig java -target=$(PLATFORM) $(CFLAGS) -java-classname=TestSerialMsg TestSerial.h TestSerialMsg -o $@

include $(MAKERULES)

