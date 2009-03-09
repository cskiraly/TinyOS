/*
 * Copyright (c) 2007, Vanderbilt University
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE VANDERBILT UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE VANDERBILT
 * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE VANDERBILT UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE VANDERBILT UNIVERSITY HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 *
 * Author: Miklos Maroti
 */

#ifndef __HPLRF2XX_H__
#define __HPLRF2XX_H__

#include <RF2xx.h>
#include <util/crc16.h>

enum
{
	/**
	 * This is the value of the TRX_CTRL_0 register
	 * which configures the output pin currents and the CLKM clock
	 */
	RF2XX_TRX_CTRL_0_VALUE = 0,

	/**
	 * This is the default value of the CCA_MODE field in the PHY_CC_CCA register
	 * which is used to configure the default mode of the clear channel assesment
	 */
	RF2XX_CCA_MODE_VALUE = RF2XX_CCA_MODE_3,

	/**
	 * This is the value of the CCA_THRES register that controls the
	 * energy levels used for clear channel assesment
	 */
	RF2XX_CCA_THRES_VALUE = 0xC7,
};

/* This is the default value of the TX_PWR field of the PHY_TX_PWR register. */
#ifndef RF230_DEF_RFPOWER
#define RF230_DEF_RFPOWER	0
#endif

#define RF2XX_DEF_RFPOWER	RF230_DEF_RFPOWER

/* This is the default value of the CHANNEL field of the PHY_CC_CCA register. */
#ifndef RF230_DEF_CHANNEL
#define RF230_DEF_CHANNEL	11
#endif

#define RF2XX_DEF_CHANNEL	RF230_DEF_CHANNEL

#define RF2XX_CHIPSET		RF230_CHIPSET

/*
 * This is the command used to calculate the CRC for the RF230 chip. 
 * TODO: Check why the default crcByte implementation is in a different endianness
 */
inline uint16_t RF2XX_CRCBYTE_COMMAND(uint16_t crc, uint8_t data)
{
	return _crc_ccitt_update(crc, data);
}

#endif//__HPLRF2XX_H__
