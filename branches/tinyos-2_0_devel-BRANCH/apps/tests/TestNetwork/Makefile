COMPONENT=TestNetworkAppC
CFLAGS += -I$(TOSDIR)/lib/net -I$(TOSDIR)/lib/net/collection

TFLAGS =  -I$(TOSDIR)/../apps/tests/TestDissemination \
          -I$(TOSDIR)/../support/sdk/c \
	  -I$(TOSDIR)/types \
          -I.

LIBMOTE = $(TOSDIR)/../support/sdk/c/libmote.a
BUILD_EXTRA_DEPS += tn-injector #tn-listener
LISTEN_OBJS = collection_msg.o test_network_msg.o tn-listener.o $(LIBMOTE)
INJECT_OBJS = set_rate_msg.o tn-injector.o $(LIBMOTE)

tn-listener: $(LISTEN_OBJS)
	gcc -v $(CFLAGS) $(TFLAGS) -o $@ $(LISTEN_OBJS)

tn-injector: $(INJECT_OBJS)
	gcc -v $(CFLAGS) $(TFLAGS) -o $@ $(INJECT_OBJS)

%.o: %.c 
	gcc $(CFLAGS) $(TFLAGS) -c -o $@ $<


test_network_msg.c:
	mig -o test_network_msg.h c -target=$(PLATFORM) $(CFLAGS) $(TFLAGS) TestNetwork.h TestNetworkMsg 

set_rate_msg.c:
	mig -o set_rate_msg.h c -target=$(PLATFORM) $(CFLAGS) $(TFLAGS) $(TOSDIR)/lib/net/DisseminationEngine.h dissemination_message

collection_msg.c:
	mig -o collection_msg.h c -target=$(PLATFORM) $(CFLAGS) $(TFLAGS) $(TOSDIR)/lib/net/collection/ForwardingEngine.h collection_header


include $(MAKERULES)

