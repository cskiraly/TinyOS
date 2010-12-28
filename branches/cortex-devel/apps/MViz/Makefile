CFLAGS += -I$(TOSDIR)/lib/printf -DRF230_DEF_CHANNEL=23 -DRF212_DEF_CHANNEL=6
#cong  -DRF230_DEF_CHANNEL=29
#cong  -DRF230_DEF_CHANNEL=25 -DRF212_DEF_CHANNEL=9

COMPONENT=MVizAppC
#CFLAGS += -I$(TOSDIR)/lib/net/ -I$(TOSDIR_CSIRO)/lib/net/ctp-multi -I$(TOSDIR_CSIRO)/lib/net/4bitle-multi -I.
CFLAGS += -I$(TOSDIR)/lib/net/ -I$(TOSDIR)/lib/net/ctp -I$(TOSDIR)/lib/net/4bitle -I.
BUILD_EXTRA_DEPS = MVizMsg.class

CFLAGS += -I$(TOSROOT)/libs

MVizMsg.java: MViz.h
	mig -target=telosb -java-classname=MVizMsg java MViz.h mviz_msg -o $@

MVizMsg.class: MVizMsg.java
	javac MVizMsg.java

include $(MAKERULES)
