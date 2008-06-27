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

#ifndef __HPLRF230_H__
#define __HPLRF230_H__

#include <RF230.h>

enum
{
	/**
	 * This is the value of the TRX_CTRL_0 register
	 * which configures the output pin currents and the CLKM clock
	 */
	RF230_TRX_CTRL_0_VALUE = 0,

	/**
	 * This is the default value of the CCA_MODE field in the PHY_CC_CCA register
	 * which is used to configure the default mode of the clear channel assesment
	 */
	RF230_CCA_MODE_VALUE = RF230_CCA_MODE_3,

	/**
	 * This is the value of the CCA_THRES register that controls the
	 * energy levels used for clear channel assesment
	 */
	RF230_CCA_THRES_VALUE = 0xC7,
};

/**
 * This is the timer type of the RF230 alarm interface
 */
typedef TOne TRF230;


/**
 * The number of alarm ticks per one second (921600)
 */
#define RF230_ALARM_SEC	((7372800UL / MHZ / 32) * (1 << MICA_DIVIDE_ONE_FOR_32KHZ_LOG2))

/**
 * The number of alarm ticks per one microsecond (0.9216)
 */
#define RF230_ALARM_MICROSEC	(RF230_ALARM_SEC / 1000000.0)

/* This is the default value of the TX_PWR field of the PHY_TX_PWR register. */
#ifndef RF230_DEF_RFPOWER
#define RF230_DEF_RFPOWER	0
#endif

/* This is the default value of the CHANNEL field of the PHY_CC_CCA register. */
#ifndef RF230_DEF_CHANNEL
#define RF230_DEF_CHANNEL	11
#endif

#endif//__HPLRF230_H__
