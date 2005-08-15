# Top-level Makefile for tools/java

SUBDIRS = net

ROOT = .
include $(ROOT)/Makefile.include

tinyos.jar: all
	rm -f tinyos.jar
	# create the jar, as update requires it to exist. we use a
	# .class file we assume always exists
	jar cf tinyos.jar net/tinyos/comm/SerialPort.class
	find . -name '*.class' | xargs jar uf tinyos.jar
