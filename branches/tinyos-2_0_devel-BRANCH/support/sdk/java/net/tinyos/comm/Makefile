#-*-Makefile-*- vim:syntax=make
#$Id: Makefile,v 1.1.2.1 2005-05-23 22:11:48 idgay Exp $

#@author Cory Sharp <cssharp@eecs.berkeley.edu>


ifndef PLATFORM
PLATFORM=linux
ifeq ($(shell [ -f /bin/cygwin1.dll ] && echo cygwin),cygwin)
PLATFORM=win32
endif
endif


TOSCOMMDIR ?= $(TOSDIR)/../tools/java/net/tinyos/comm
INSTALLDIR ?= /usr/local/bin
JAVADIR ?= $(shell x="`which javac`"; echo $${x%/bin/javac})
JAVADIR ?= $(shell perl -e '($$x=`which javac`)=~s{/[^/]+/javac$$}{}; print $$x')
BUILDDIR ?= build_$(PLATFORM)

#  JavaxCommSerialPort.java \

JAVADEPS = \
  build_$(PLATFORM)/NativeSerial.java \
  build_$(PLATFORM)/TOSComm.java \
  build_$(PLATFORM)/TOSCommJNI.java \
  ByteQueue.java \
  SerialPort.java \
  SerialPortEvent.java \
  SerialPortListener.java \
  TOSCommLibraryLoader.java \
  TOSSerial.java \
  UnsupportedCommOperationException.java

JAVAOBJS = $(JAVADEPS:%.java=%.class)

SWIGDEPS = \
  TOSComm.i \
  NativeSerial.h

SWIGOBJS0 = \
  NativeSerial.java \
  TOSComm.java \
  TOSCommJNI.java \
  TOSComm_wrap.cxx

SWIGOBJS = $(addprefix $(BUILDDIR)/,$(SWIGOBJS0))


all: lib java

swig: builddir $(SWIGOBJS)
	@:

java: builddir $(JAVAOBJS)
	@:

builddir: $(BUILDDIR)
	@:


include Makefile.$(PLATFORM)


$(JAVAOBJS): $(JAVADEPS)
	javac $(JAVADEPS)

$(BUILDDIR):
	mkdir $(BUILDDIR)


clean: FORCE
	rm -f *.class
	rm -rf $(BUILDDIR)


.PHONY: all lib swig java builddir install uninstall clean FORCE

