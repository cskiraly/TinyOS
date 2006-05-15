BASE_DIR = $(TOSROOT)/apps/tests/TestRadioPM/apps

COMPONENT=TestGatewayNodeAppC

CFLAGS += -I$(BASE_DIR)/../apps/TestUPMA
include $(BASE_DIR)/TestUPMA/MakeIncludes

BUILD_EXTRA_DEPS += MsgCountMsg.class PrintMsgCountMsgs.class

%.class: %.java
	javac $<

MsgCountMsg.java: MsgCountMsg.h
	mig java -target=$(PLATFORM) $(CFLAGS) -java-classname=MsgCountMsg MsgCountMsg.h MsgCountMsg -o $@


include $(MAKERULES)

