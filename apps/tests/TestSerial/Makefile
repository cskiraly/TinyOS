COMPONENT=TestSerialAppC
CFLAGS += -I$(TOSDIR)/lib/serial -I$(TOSDIR)/lib/oski
BUILD_EXTRA_DEPS += TestSerialMsg.class TestSerial.class

%.class: %.java
	javac $<

TestSerialMsg.java:
	mig java -target=$(PLATFORM) $(CFLAGS) -java-classname=TestSerialMsg TestSerial.h TestSerialMsg -o $@


include $(MAKERULES)

