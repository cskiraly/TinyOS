/// $Id: ATm128GPIO.h,v 1.1.2.1 2005-03-17 14:42:29 mturon Exp $

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

#ifndef _H_ATm128GPIO_h
#define _H_ATm128GPIO_h

//====================== GPIO ==================================

typedef uint8_t ATm128_PORTA_t;        //!< PortA: 8-pin GPIO Data
typedef uint8_t ATm128_DDRA_t;         //!< PortA: 8-pin GPIO Direction
typedef uint8_t ATm128_PINA_t;         //!< PortA: 8-pin GPIO Address

typedef uint8_t ATm128_PORTB_t;        //!< PortB: 8-pin GPIO Data
typedef uint8_t ATm128_DDRB_t;         //!< PortB: 8-pin GPIO Direction
typedef uint8_t ATm128_PINB_t;         //!< PortB: 8-pin GPIO Address

typedef uint8_t ATm128_PORTC_t;        //!< PortC: 8-pin GPIO Data
typedef uint8_t ATm128_DDRC_t;         //!< PortC: 8-pin GPIO Direction
typedef uint8_t ATm128_PINC_t;         //!< PortC: 8-pin GPIO Address

typedef uint8_t ATm128_PORTD_t;        //!< PortD: 8-pin GPIO Data
typedef uint8_t ATm128_DDRD_t;         //!< PortD: 8-pin GPIO Direction
typedef uint8_t ATm128_PIND_t;         //!< PortD: 8-pin GPIO Address

typedef uint8_t ATm128_PORTE_t;        //!< PortE: 8-pin GPIO Data
typedef uint8_t ATm128_DDRE_t;         //!< PortE: 8-pin GPIO Direction
typedef uint8_t ATm128_PINE_t;         //!< PortE: 8-pin GPIO Address

typedef uint8_t ATm128_PORTF_t;        //!< PortF: 8-pin GPIO Data
typedef uint8_t ATm128_DDRF_t;         //!< PortF: 8-pin GPIO Direction
typedef uint8_t ATm128_PINF_t;         //!< PortF: 8-pin GPIO Address

typedef uint8_t ATm128_PORTG_t;        //!< PortG: 5-pin GPIO Data
typedef uint8_t ATm128_DDRG_t;         //!< PortG: 5-pin GPIO Direction
typedef uint8_t ATm128_PING_t;         //!< PortG: 5-pin GPIO Address

#endif //_H_ATm128GPIO_h

