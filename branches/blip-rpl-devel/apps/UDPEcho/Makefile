COMPONENT=UDPEchoC
# uncomment this for network programming support
# BOOTLOADER=tosboot

# CFLAGS += -DCC2420_DEF_CHANNEL=26
# CFLAGS += -DRF230_DEF_CHANNEL=26
# CFLAGS += -DCC2420_DEF_RFPOWER=4 -DENABLE_SPI0_DMA
PFLAGS += -DENABLE_SPI0_DMA

# disables support for the AM stack, which somewhat reduces code size
# and compresses packet formats.  If you want to use other tinyos
# protocols which are AM-based, you should not include this.
# CFLAGS += -DIEEE154FRAMES_ENABLED

# lib6lowpan contains inet_ntop6 and inet_pton6 to process ascii
# representations of IPv6 addresses.  You can remove them to save some
# code if you don't use them
# CFLAGS += -DNO_LIB6LOWPAN_ASCII

# you can compile with or without a routing protocol... of course,
# without it, you will only be able to use link-local communication
PFLAGS += -DRPL_ROUTING -DRPL_STORING_MODE -I$(LOWPAN_ROOT)/tos/lib/net/rpl
# PFLAGS += -DBLIP_L2_RETRIES # -DLIB6LOWPAN_HC_VERSION=-1

# if this is set, motes will send debugging information to the address
# listed.
# CFLAGS += -DREPORT_DEST=\"2001:470:1f04:56d::64\"
# CFLAGS += -DREPORT_DEST=\"fe80::22:ff:fe00:1\"
# CFLAGS += -DREPORT_DEST=\"fec0::1\"

# printf debugs.  works only on telosb/tmote sky
# PFLAGS += -DPRINTFUART_ENABLED
# PFLAGS += -DIN6_PREFIX=\"fec0::\"                                                                                                                       
include $(MAKERULES)

