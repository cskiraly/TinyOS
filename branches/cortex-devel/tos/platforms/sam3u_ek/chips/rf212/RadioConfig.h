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
/*
 * Adjusted for CSIRO fleck3c, 2009
 *
 * Christian.Richter@csiro.au
 */
#ifndef __RADIOCONFIG_H__
#define __RADIOCONFIG_H__


#include <RF212DriverLayer.h>


/* See the README in the TOSROOT/chips/rf2xx folder */
//#define LOW_POWER_LISTENING

enum
{
	/**
	 * This is the value of the TRX_CTRL_0 register
	 * which configures the output pin currents and the CLKM clock
	 */
	RF212_TRX_CTRL_0_VALUE = 0,

	/**
	 * This is the default value of the CCA_MODE field in the PHY_CC_CCA register
	 * which is used to configure the default mode of the clear channel assesment
	 */
	RF212_CCA_MODE_VALUE = RF212_CCA_MODE_3,

	/**
	 * This is the value of the CCA_THRES register that controls the
	 * energy levels used for clear channel assesment
	 */
	RF212_CCA_THRES_VALUE = 0xC7,
};

/* This is the default value of the TX_PWR field of the PHY_TX_PWR register. */
#ifndef RF212_DEF_RFPOWER
#define RF212_DEF_RFPOWER	0xc0
#endif


/* This is the default value of the CHANNEL field of the PHY_CC_CCA register. */
#ifndef RF212_DEF_CHANNEL
#define RF212_DEF_CHANNEL	6
#warning "RF212 Channel is 6"
#endif

typedef TMilli TRadio;


/**
 * The number of radio alarm ticks per one microsecond (0.9216). 
 * We use integers and no parentheses just to make deputy happy.
 */
#define RADIO_ALARM_MICROSEC	(1024)

/**
 * The base two logarithm of the number of radio alarm ticks per one millisecond
 */
#define RADIO_ALARM_MILLI_EXP	(5)

#endif//__RADIOCONFIG_H__
