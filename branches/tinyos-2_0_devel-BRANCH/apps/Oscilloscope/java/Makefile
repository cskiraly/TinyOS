all: Oscilloscope.class

OscilloscopeMsg.java: ../Oscilloscope.h
	mig -target=null -java-classname=OscilloscopeMsg java ../Oscilloscope.h oscilloscope -o $@

Constants.java: ../Oscilloscope.h
	ncg -target=null -java-classname=Constants java ../Oscilloscope.h Oscilloscope.h -o $@

Oscilloscope.class: $(wildcard *.java) OscilloscopeMsg.java Constants.java
	javac *.java
