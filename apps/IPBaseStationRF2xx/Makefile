COMPONENT=BaseStationC
CFLAGS += -DTIME_SYNC -I$(TOSDIR_CSIRO)/lib/ftsp

#CFLAGS += -I$(TOSDIR)/lib/printf -DUSE_RF230_RADIO -DRF230_DEF_CHANNEL=18 -DREPORT_DEST='"fec0::64"' -DBLIP_STATS
 CFLAGS += -I$(TOSDIR)/lib/printf -DUSE_RF212_RADIO -DRF212_DEF_CHANNEL=7  -DREPORT_DEST='"fec0::64"' -DBLIP_STATS
# CFLAGS += -DCC2420_DEF_CHANNEL=18
# CFLAGS += -DCC2420_DEF_RFPOWER=4

PFLAGS += -I$(TOSDIR_CSIRO)/lib/net/blip
PFLAGS += -I$(TOSDIR_CSIRO)/lib/net/blip/platform

% CFLAGS += -DPLATFORM_BAUDRATE=57600L
  CFLAGS += -DPLATFORM_BAUDRATE=125000L -DUBRR0_VAL=7 #setserial <dev> spd_cust divisor 200
% CFLAGS += -DPLATFORM_BAUDRATE=250000L -DUBRR0_VAL=3 #setserial <dev> spd_cust divisor 100
% CFLAGS += -DPLATFORM_BAUDRATE=500000L -DUBRR0_VAL=1 #setserial <dev> spd_cust divisor 50
CFLAGS += -DTASKLET_IS_TASK

# radio options.  channel settings will be overridden by the driver
# CFLAGS += -DCC2420_DEF_RFPOWER=4
#CFLAGS += -DRF212_PHYMODE=0x3e 
#CFLAGS += -DRF212_PHYMODE=RF212_OQPSK_SIN_1000_SCR_ON
#CFLAGS += -DRF212_PHYMODE=0 -DSOFTWAREACK_TIMEOUT=30000#RF212_BPSK_20

# this is necessary, otherwise we will allocate a heap by including
# the lowpan target
CFLAGS += -DNO_IP_MALLOC 

# this aligns the 802.15.4 payload on the data field of a message_t.
# very convenient for forwarding, and means we don't have to do a
# memmove.  This doesn't mean that motes running blip also need this--
# they can use IFRAMES or IEEE154FRAMES
#CFLAGS += -DIEEE154FRAMES_ENABLED


# CFLAGS += -DLOW_POWER_LISTENING
# CFLAGS += -DLPL_DEF_LOCAL_WAKEUP=512*2
# CFLAGS += -DLPL_DEF_REMOTE_WAKEUP=512*2
# CFLAGS += -DDELAY_AFTER_RECEIVE=20

# if you're worried about your interface mote crashing, enable this to
# turn on a hardware watchdog that will reset it if it does.  CFLAGS
# += -DBLIP_WATCHDOG
#
# debugging
#

# filter packets based on a specified topology
# PFLAGS += -I../UDPEcho/NodeConnectivity -DSW_TOPOLOGY

# part of the test harness
# CFLAGS += -DDBG_TRACK_FLOWS

# for simulation
# CFLAGS += -DBASESTATION_ID=100

# defs for snooping-- handy for debugging LPL, etc.
# CFLAGS += -DCC2420_NO_UNIQUE
# CFLAGS += -DCC2420_DEF_CHANNEL=15
# CFLAGS += -DCC2420_NO_ACKNOWLEDGEMENTS
# CFLAGS += -DCC2420_NO_ADDRESS_RECOGNITION

include $(MAKERULES)

