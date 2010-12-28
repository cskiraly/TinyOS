COMPONENT=UDPEchoC

CFLAGS += -DBLIP_EXTRA_BYTES=40
#CFLAGS += -I$(TOSDIR)/lib/printf -DUSE_RF230_RADIO -DRF230_DEF_CHANNEL=18 -DREPORT_DEST='"fec0::64"' -DBLIP_STATS
 CFLAGS += -I$(TOSDIR)/lib/printf -DUSE_RF212_RADIO -DRF212_DEF_CHANNEL=7  -DREPORT_DEST='"fec0::64"' -DBLIP_STATS
# CFLAGS += -DCC2420_DEF_CHANNEL=18
# CFLAGS += -DCC2420_DEF_RFPOWER=4
# CFLAGS += -DRF212_PHYMODE=RF212_OQPSK_SIN_1000_SCR_ON

PFLAGS += -I$(TOSDIR_CSIRO)/lib/net/blip
PFLAGS += -I$(TOSDIR_CSIRO)/lib/net/blip/platform

# uncomment this for network programming support
# BOOTLOADER=tosboot

# previous wen's stuff
# DELUGE_DIR ?= $(TOSDIR)/lib/net/Deluge
# DELUGE_EXTRA ?= $(DELUGE_DIR)/extra
# CFLAGS += -DDELUGE
# CFLAGS += -I$(DELUGE_EXTRA)/fleck3c -I$(DELUGE_EXTRA)/micaz -I$(DELUGE_EXTRA)/mica2
# CFLAGS += -I$(DELUGE_EXTRA)/avr -I$(DELUGE_EXTRA)
# BOOTLOADER_IMG ?= $(TOSBOOT_DIR)/iris/main.ihex
# AVR_FUSE_H ?= 0xda
    

# disables support for the AM stack, which somewhat reduces code size
# and compresses packet formats.  If you want to use other tinyos
# protocols which are AM-based, you should not include this.
CFLAGS += -DIEEE154FRAMES_ENABLED

#CFLAGS += -DLOW_POWER_LISTENING
#CFLAGS += -DLPL_DEF_LOCAL_WAKEUP=512*2
#CFLAGS += -DLPL_DEF_REMOTE_WAKEUP=512*2
#CFLAGS += -DDELAY_AFTER_RECEIVE=20


# lib6lowpan contains inet_ntop6 and inet_pton6 to process ascii
# representations of IPv6 addresses.  You can remove them to save some
# code if you don't use them
# CFLAGS += -DNO_LIB6LOWPAN_ASCII

BUILD_EXTRA_DEPS = UdpReport.py

UdpReport.py: UDPReport.h
	mig -DMIG -I$(TOSROOT)/tos/lib/net/blip -I$(TOSROOT)/tos/chips/cc2420 -I$(TOSROOT)/support/sdk/c/blip/include  python -python-classname=UdpReport UDPReport.h udp_report -o util/UdpReport.py


include $(MAKERULES)

