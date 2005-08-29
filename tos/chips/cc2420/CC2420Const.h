// $Id: CC2420Const.h,v 1.1.2.5 2005-08-29 00:46:56 scipio Exp $
/*
 * "Copyright (c) 2000-2005 The Regents of the University  of California.
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 *
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 */

/**
 * ChipCon 2420 radio constants.
 *
 * <pre>
 *  $Id: CC2420Const.h,v 1.1.2.5 2005-08-29 00:46:56 scipio Exp $
 * </pre>
 *
 * @author Phil Levis
 * @author Joe Polastre
 * @date   August 28 2005
 */

#ifndef _CC2420CONST_H
#define _CC2420CONST_H

typedef nx_struct CC2420Header {
  nx_uint8_t length;
  nx_uint16_t fcf;
  nx_uint8_t dsn;
  nx_uint16_t destpan;
  nx_uint16_t addr;
  nx_uint8_t type;
} CC2420Header;

typedef nx_struct CC2420Footer {
} CC2420Footer;

typedef nx_struct CC2420Metadata {
  nx_uint8_t strength;
  nx_uint8_t lqi;
  nx_bool crc;
  nx_bool ack;
  nx_uint16_t time;
} CC2420Metadata;

// times for the CC2420 in microseconds
enum {
  CC2420_TIME_BIT = 4,
  CC2420_TIME_BYTE = CC2420_TIME_BIT << 3,
  CC2420_TIME_SYMBOL = 16
};

#ifndef TOSH_DATA_LENGTH
#define TOSH_DATA_LENGTH 28
#endif

enum {
  // size of the header not including the length byte
  MAC_HEADER_SIZE = sizeof(CC2420Header) - 1,
  // size of the footer (FCS field)
  MAC_FOOTER_SIZE = sizeof(uint16_t),
  // size of the data length
  DATA_LENGTH = TOSH_DATA_LENGTH,
  // size of the full packet
  MAC_DATA_SIZE = DATA_LENGTH + MAC_HEADER_SIZE + MAC_FOOTER_SIZE,
  // position of the length byte
  LENGTH_BYTE_NUMBER = 1,
};

// TinyOS default RF channel
#ifdef TOS_DEF_CHANNEL
#define CC2420_DEF_CHANNEL          (TOS_DEF_CHANNEL + 11)
#endif

// TinyOS default RF output power
#ifdef TOS_DEF_RFPOWER
#define CC2420_DEF_RFPOWER          (TOS_DEF_RFPOWER >> 3)
#endif

#ifndef CC2420_DEF_CHANNEL
#define CC2420_DEF_CHANNEL	    11  //channel select
#endif

#ifndef CC2420_DEF_RFPOWER
#define CC2420_DEF_RFPOWER          0x1F
#endif

enum {
  CC2420_MIN_CHANNEL =              11,
  CC2420_MAX_CHANNEL =              26,
  TOS_MAX_CHANNELS   =              CC2420_MAX_CHANNEL-CC2420_MIN_CHANNEL+1,
};

enum {
  CC2420_DEF_PRESET =          2405,  //freq select

  CC2420_DEF_FCF  =            0x0108,  // without ACK
  CC2420_DEF_FCF_ACK =         0x2108,  // with ACK
  CC2420_DEF_FCF_TYPE_BEACON = 0x0000,
  CC2420_DEF_FCF_TYPE_DATA =   0x0100,
  CC2420_DEF_FCF_TYPE_ACK =    0x0200,
  CC2420_DEF_FCF_TYPE_MASK =   0x0700,
  CC2420_DEF_FCF_BIT_ACK  =    13,
  CC2420_DEF_BACKOFF =         500,
  CC2420_SYMBOL_TIME =         16, // 2^4
// 20 symbols make up a backoff period
// 10 jiffy's make up a backoff period
// due to timer overhead, 30.5us is close enough to 32us per 2 symbols
  CC2420_SYMBOL_UNIT =         10,
 
// delay when waiting for the ack
#ifndef CC2420_ACK_DELAY
  CC2420_ACK_DELAY =           75,
#endif

#ifndef CC2420_XOSC_TIMEOUT
  CC2420_XOSC_TIMEOUT = 200,     //times to chk if CC2420 crystal is on
#endif

  CC2420_SNOP   =          0x00,
  CC2420_SXOSCON  =        0x01,
  CC2420_STXCAL =          0x02,
  CC2420_SRXON  =          0x03,
  CC2420_STXON   =         0x04,
  CC2420_STXONCCA =        0x05,
  CC2420_SRFOFF =          0x06,
  CC2420_SXOSCOFF =        0x07,
  CC2420_SFLUSHRX =        0x08,
  CC2420_SFLUSHTX        = 0x09,
  CC2420_SACK            = 0x0A,
  CC2420_SACKPEND        = 0x0B,
  CC2420_SRXDEC          = 0x0C,
  CC2420_STXENC          = 0x0D,
  CC2420_SAES            = 0x0E,
  CC2420_NOTUSED         = 0x0F,
  CC2420_MAIN            = 0x10,
  CC2420_MDMCTRL0        = 0x11,
  CC2420_MDMCTRL1        = 0x12,
  CC2420_RSSI            = 0x13,
  CC2420_SYNCWORD        = 0x14,
  CC2420_TXCTRL          = 0x15,
  CC2420_RXCTRL0         = 0x16,
  CC2420_RXCTRL1         = 0x17,
  CC2420_FSCTRL          = 0x18,
  CC2420_SECCTRL0        = 0x19,
  CC2420_SECCTRL1        = 0x1A,
  CC2420_BATTMON         = 0x1B,
  CC2420_IOCFG0          = 0x1C,
  CC2420_IOCFG1          = 0x1D,
  CC2420_MANFIDL         = 0x1E,
  CC2420_MANFIDH         = 0x1F,
  CC2420_FSMTC           = 0x20,
  CC2420_MANAND          = 0x21,
  CC2420_MANOR           = 0x22,
  CC2420_AGCCTRL         = 0x23,
  CC2420_AGCTST0         = 0x24,
  CC2420_AGCTST1         = 0x25,
  CC2420_AGCTST2         = 0x26,
  CC2420_FSTST0          = 0x27,
  CC2420_FSTST1          = 0x28,
  CC2420_FSTST2          = 0x29,
  CC2420_FSTST3          = 0x2A,
  CC2420_RXBPFTST        = 0x2B,
  CC2420_FSMSTATE        = 0x2C,
  CC2420_ADCTST          = 0x2D,
  CC2420_DACTST          = 0x2E,
  CC2420_TOPTST          = 0x2F,
  CC2420_RESERVED        = 0x30,
  CC2420_TXFIFO          = 0x3E,
  CC2420_RXFIFO          = 0x3F,

  CC2420_RAM_SHORTADR    = 0x16A,
  CC2420_RAM_PANID       = 0x168,
  CC2420_RAM_IEEEADR     = 0x160,
  CC2420_RAM_CBCSTATE    = 0x150,
  CC2420_RAM_TXNONCE     = 0x140,
  CC2420_RAM_KEY1        = 0x130,
  CC2420_RAM_SABUF       = 0x120,
  CC2420_RAM_RXNONCE     = 0x110,
  CC2420_RAM_KEY0        = 0x100,
  CC2420_RAM_RXFIFO      = 0x080,
  CC2420_RAM_TXFIFO      = 0x000,

// MDMCTRL0 Register Bit Positions
  CC2420_MDMCTRL0_FRAME       = 13,  // 0 : reject reserved frame types, 1 = accept
  CC2420_MDMCTRL0_PANCRD      = 12,  // 0 : not a PAN coordinator
  CC2420_MDMCTRL0_ADRDECODE   = 11,  // 1 : enable address decode
  CC2420_MDMCTRL0_CCAHIST     =  8,   // 3 bits (8,9,10) : CCA hysteris in db
  CC2420_MDMCTRL0_CCAMODE     =  6,   // 2 bits (6,7)    : CCA trigger modes
  CC2420_MDMCTRL0_AUTOCRC     =  5,   // 1 : generate/chk CRC
  CC2420_MDMCTRL0_AUTOACK     =  4,   // 1 : Ack valid packets
  CC2420_MDMCTRL0_PREAMBL     =  0,   // 4 bits (0..3): Preamble length

// MDMCTRL1 Register Bit Positions
  CC2420_MDMCTRL1_CORRTHRESH  =  6,   // 5 bits (6..10) : correlator threshold
  CC2420_MDMCTRL1_DEMOD_MODE  =  5,   // 0: lock freq after preamble match, 1: continous udpate
  CC2420_MDMCTRL1_MODU_MODE   =  4,   // 0: IEEE 802.15.4
  CC2420_MDMCTRL1_TX_MODE     =  2,   // 2 bits (2,3) : 0: use buffered TXFIFO
  CC2420_MDMCTRL1_RX_MODE     =  0,   // 2 bits (0,1) : 0: use buffered RXFIFO

// RSSI Register Bit Positions
  CC2420_RSSI_CCA_THRESH      =  8,   // 8 bits (8..15) : 2's compl CCA threshold

// TXCTRL Register Bit Positions
  CC2420_TXCTRL_BUFCUR        = 14,  // 2 bits (14,15) : Tx mixer buffer bias current
  CC2420_TXCTRL_TURNARND      = 13,  // wait time after STXON before xmit
  CC2420_TXCTRL_VAR           = 11,  // 2 bits (11,12) : Varactor array settings
  CC2420_TXCTRL_XMITCUR       =  9,  // 2 bits (9,10)  : Xmit mixer currents
  CC2420_TXCTRL_PACUR         =  6,   // 3 bits (6..8)  : PA current
  CC2420_TXCTRL_PADIFF        =  5,   // 1: Diff PA, 0: Single ended PA
  CC2420_TXCTRL_PAPWR         =  0,   // 5 bits (0..4): Output PA level

// Mask for the CC2420_TXCTRL_PAPWR register for RF power

// RXCTRL0 Register Bit Positions
  CC2420_RXCTRL0_BUFCUR       = 12,  // 2 bits (12,13) : Rx mixer buffer bias current
  CC2420_RXCTRL0_HILNAG       = 10,  // 2 bits (10,11) : High gain, LNA current
  CC2420_RXCTRL0_MLNAG        =  8,  // 2 bits (8,9)   : Med gain, LNA current
  CC2420_RXCTRL0_LOLNAG       =  6,  // 2 bits (6,7)   : Lo gain, LNA current
  CC2420_RXCTRL0_HICUR        =  4,  // 2 bits (4,5)   : Main high LNA current
  CC2420_RXCTRL0_MCUR         =  2,  // 2 bits (2,3)   : Main med  LNA current
  CC2420_RXCTRL0_LOCUR        =  0,  // 2 bits (0,1)   : Main low LNA current

// RXCTRL1 Register Bit Positions
  CC2420_RXCTRL1_LOCUR        = 13,  // Ref bias current to Rx bandpass filter
  CC2420_RXCTRL1_MIDCUR       = 12,  // Ref bias current to Rx bandpass filter
  CC2420_RXCTRL1_LOLOGAIN     = 11,  // LAN low gain mode
  CC2420_RXCTRL1_MEDLOGAIN    = 10,  // LAN low gain mode
  CC2420_RXCTRL1_HIHGM        =  9,  // Rx mixers, hi gain mode
  CC2420_RXCTRL1_MEDHGM       =  8,  // Rx mixers, hi gain mode
  CC2420_RXCTRL1_LNACAP       =  6,  // 2 bits (6,7) Selects LAN varactor array setting
  CC2420_RXCTRL1_RMIXT        =  4,  // 2 bits (4,5) Receiver mixer output current
  CC2420_RXCTRL1_RMIXV        =  2,  // 2 bits (2,3) VCM level, mixer feedback
  CC2420_RXCTRL1_RMIXCUR      =  0,  // 2 bits (0,1) Receiver mixer current
 
  //  FSCTRL Register Bit Positions
  CC2420_FSCTRL_LOCK          = 14, // 2 bits (14,15) # of clocks for synch
  CC2420_FSCTRL_CALDONE       = 13, // Read only, =1 if cal done since freq synth turned on
  CC2420_FSCTRL_CALRUNING     = 12, // Read only, =1 if cal in progress
  CC2420_FSCTRL_LOCKLEN       = 11, // Synch window pulse width
  CC2420_FSCTRL_LOCKSTAT      = 10, // Read only, = 1 if freq synthesizer is loced
  CC2420_FSCTRL_FREQ          =  0, // 10 bits, set operating frequency 

// SECCTRL0 Register Bit Positions
  CC2420_SECCTRL0_PROTECT      =  9, // Protect enable Rx fifo
  CC2420_SECCTRL0_CBCHEAD      =  8, // Define 1st byte of CBC-MAC
  CC2420_SECCTRL0_SAKEYSEL     =  7, // Stand alone key select
  CC2420_SECCTRL0_TXKEYSEL     =  6, // Tx key select
  CC2420_SECCTRL0_RXKEYSEL     =  5, // Rx key select
  CC2420_SECCTRL0_SECM         =  2, // 2 bits (2..4) # of bytes in CBC-MAX auth field
  CC2420_SECCTRL0_SECMODE      =  0, // Security mode

// SECCTRL1 Register Bit Positions
  CC2420_SECCTRL1_TXL          =  8, // 7 bits (8..14) Tx in-line security
  CC2420_SECCTRL1_RXL          =  0, // 7 bits (0..7)  Rx in-line security

// BATTMON  Register Bit Positions
  CC2420_BATTMON_OK            =  6, // Read only, batter voltage OK
  CC2420_BATTMON_EN            =  5, // Enable battery monitor
  CC2420_BATTMON_VOLT          =  0, // 5 bits (0..4) Battery toggle voltage
 
// IOCFG0 Register Bit Positions
  CC2420_IOCFG0_FIFOPOL        = 10, // Fifo signal polarity
  CC2420_IOCFG0_FIFOPPOL       =  9, // FifoP signal polarity
  CC2420_IOCFG0_SFD            =  8, // SFD signal polarity
  CC2420_IOCFG0_CCAPOL         =  7, // CCA signal polarity
  CC2420_IOCFG0_FIFOTHR        =  0, // 7 bits, (0..6) # of Rx bytes in fifo to trg fifop

// IOCFG1 Register Bit Positions
  CC2420_IOCFG1_HSSD           = 10, // 2 bits (10,11) HSSD module config
  CC2420_IOCFG1_SFDMUX         =  5, // 5 bits (5..9)  SFD multiplexer pin settings
  CC2420_IOCFG1_CCAMUX         =  0, // 5 bits (0..4)  CCA multiplexe pin settings
};

#define  CC2420_TXCTRL_PAPWR_MASK  (0x1F << CC2420_TXCTRL_PAPWR)
// Current Parameter Arrray Positions
enum{
 CP_MAIN = 0,
 CP_MDMCTRL0,
 CP_MDMCTRL1,
 CP_RSSI,
 CP_SYNCWORD,
 CP_TXCTRL,
 CP_RXCTRL0,
 CP_RXCTRL1,
 CP_FSCTRL,
 CP_SECCTRL0,
 CP_SECCTRL1,
 CP_BATTMON,
 CP_IOCFG0,
 CP_IOCFG1
} ;

/* Status byte returned by CC2420 on SPI operations. */
typedef uint8_t cc2420_so_status_t;

// STATUS Bit Posititions
enum {
  CC2420_XOSC16M_STABLE	= 6,
  //CC2420_TX_UNDERFLOW   = 5,
  //CC2420_ENC_BUSY       = 1 << 4,
  CC2420_TX_ACTIVE      = 1 << 3,
  //CC2420_LOCK           = 2,
  //CC2420_RSSI_VALID     = 1,
};

#endif /* _CC2420CONST_H */
