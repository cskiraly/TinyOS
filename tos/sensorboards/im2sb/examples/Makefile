COMPONENT=TestSensorC
CFLAGS += -I%T/lib/oski
BUILD_EXTRA_DEPS += TestSensor.class
CLEAN_EXTRA = *.class TestSensorMsg.java
SENSORBOARD ?= im2sb

TestSensor.class: $(wildcard *.java) TestSensorMsg.java
	javac *.java

TestSensorMsg.java:
	mig java -target=null $(CFLAGS) -java-classname=TestSensorMsg TestSensor.h TestSensorMsg -o $@


include $(MAKERULES)