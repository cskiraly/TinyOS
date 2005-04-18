/// $Id: ATm128Power.h,v 1.1.2.1 2005-04-18 08:18:31 mturon Exp $

/**
 * Copyright (c) 2004-2005 Crossbow Technology, Inc.  All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL CROSSBOW TECHNOLOGY OR ANY OF ITS LICENSORS BE LIABLE TO 
 * ANY PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL 
 * DAMAGES ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN
 * IF CROSSBOW OR ITS LICENSOR HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH 
 * DAMAGE. 
 *
 * CROSSBOW TECHNOLOGY AND ITS LICENSORS SPECIFICALLY DISCLAIM ALL WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY 
 * AND FITNESS FOR A PARTICULAR PURPOSE. THE SOFTWARE PROVIDED HEREUNDER IS 
 * ON AN "AS IS" BASIS, AND NEITHER CROSSBOW NOR ANY LICENSOR HAS ANY 
 * OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR 
 * MODIFICATIONS.
 */

/// @author Martin Turon <mturon@xbow.com>

#ifndef _H_ATm128Power_h
#define _H_ATm128Power_h

//================== ATmega128 Power Management ==========================

/** Sleep modes */
enum {
    ATM128_SLEEP_IDLE = 0, 
    ATM128_SLEEP_ADC,
    ATM128_SLEEP_POWER_DOWN,
    ATM128_SLEEP_POWER_SAVE,
    ATM128_SLEEP_STANDBY = 3,             //!< enable standby bit (sm2)
    ATM128_SLEEP_EXTENDED_STANDBY = 4,    //!< enable standby bit (sm2)
};

/** MCU Control Register */
typedef struct
{
    uint8_t ivce  : 1;  //!< Interrupt Vector Change Enable
    uint8_t ivsel : 1;  //!< Interrupt Vector Select 
    uint8_t stdby : 1;  //!< Standby Enable (sm2) 
    uint8_t sm    : 2;  //!< Sleep Mode
    uint8_t se    : 1;  //!< Sleep Enable
    uint8_t srw10 : 1;  //!< SRAM wait state enable
    uint8_t srw   : 1;  //!< External SRAM enable
} ATm128_MCUCR_t;

#endif //_H_ATm128Power_h

