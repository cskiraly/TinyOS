/// $Id: ATm128ADC.h,v 1.1.2.2 2005-02-03 01:16:07 mturon Exp $

/**
 * Copyright (c) 2004-2005 Crossbow Technology, Inc.  All rights reserved.
 *
 * Permission to use, copy, modify and distribute, this software and 
 * documentation is granted, provided the following conditions are met:
 *   1. The above copyright notice and these conditions, along with the 
 *      following disclaimers, appear in all copies of the software.
 *   2. When the use, copying, modification or distribution is for COMMERCIAL 
 *      purposes (i.e., any use other than academic research), then the 
 *      software (including all modifications of the software) may be used 
 *      ONLY with hardware manufactured by and purchased from Crossbow 
 *      Technology, unless you obtain separate written permission from, 
 *      and pay appropriate fees to, Crossbow. For example, no right to copy 
 *      and use the software on non-Crossbow hardware, if the use is 
 *      commercial in nature, is permitted under this license. 
 *   3. When the use, copying, modification or distribution is for 
 *      NON-COMMERCIAL PURPOSES (i.e., academic research use only), the 
 *      software may be used, whether or not with Crossbow hardware, without 
 *      any fee to Crossbow. 
 * 
 * IN NO EVENT SHALL CROSSBOW TECHNOLOGY OR ANY OF ITS LICENSORS BE LIABLE TO 
 * ANY PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL 
 * DAMAGES ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN
 * IF CROSSBOW OR ITS LICENSOR HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH 
 * DAMAGE. CROSSBOW TECHNOLOGY AND ITS LICENSORS SPECIFICALLY DISCLAIM ALL 
 * WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF 
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE SOFTWARE PROVIDED
 * HEREUNDER IS ON AN "AS IS" BASIS, AND NEITHER CROSSBOW NOR ANY LICENSOR HAS
 * ANY OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR 
 * MODIFICATIONS.
 */

/// @author Martin Turon <mturon@xbow.com>

#ifndef _H_ATm128ADC_h
#define _H_ATm128ADC_h

//================== 8 channel 10-bit ADC ==============================

/** Voltage Reference Settings */
enum {
    ATM128_ADC_VREF_OFF = 0,
    ATM128_ADC_VREF_AVCC = 1,
    ATM128_ADC_VREF_RSVD,
    ATM128_ADC_VREF_2_56 = 3,
};

/** ADC Multiplexer Settings */
enum {
    ATM128_ADC_SNGL_ADC0 = 0,
    ATM128_ADC_SNGL_ADC1,
    ATM128_ADC_SNGL_ADC2,
    ATM128_ADC_SNGL_ADC3,
    ATM128_ADC_SNGL_ADC4,
    ATM128_ADC_SNGL_ADC5,
    ATM128_ADC_SNGL_ADC6,
    ATM128_ADC_SNGL_ADC7,
    ATM128_ADC_DIFF_ADC00_10x,
    ATM128_ADC_DIFF_ADC10_10x,
    ATM128_ADC_DIFF_ADC00_200x,
    ATM128_ADC_DIFF_ADC10_200x,
    ATM128_ADC_DIFF_ADC22_10x,
    ATM128_ADC_DIFF_ADC32_10x,
    ATM128_ADC_DIFF_ADC22_200x,
    ATM128_ADC_DIFF_ADC32_200x,
    ATM128_ADC_DIFF_ADC01_1x,
    ATM128_ADC_DIFF_ADC11_1x,
    ATM128_ADC_DIFF_ADC21_1x,
    ATM128_ADC_DIFF_ADC31_1x,
    ATM128_ADC_DIFF_ADC41_1x,
    ATM128_ADC_DIFF_ADC51_1x,
    ATM128_ADC_DIFF_ADC61_1x,
    ATM128_ADC_DIFF_ADC71_1x,
    ATM128_ADC_DIFF_ADC02_1x,
    ATM128_ADC_DIFF_ADC12_1x,
    ATM128_ADC_DIFF_ADC22_1x,
    ATM128_ADC_DIFF_ADC32_1x,
    ATM128_ADC_DIFF_ADC42_1x,
    ATM128_ADC_DIFF_ADC52_1x,
    ATM128_ADC_SNGL_1_23,
    ATM128_ADC_SNGL_GND,
};

/** ADC Multiplexer Settings Register */
typedef struct
{
    uint8_t refs  : 2;  //!< Reference Selection Bits
    uint8_t adlar : 1;  //!< ADC Left Adjust Result
    uint8_t mux   : 5;  //!< Analog Channel and Gain Selection Bits
} ATm128ADCSettings_t;

typedef ATm128ADCSettings_t ATm128_ADMUX_t;  //!< ADC Multiplexer Selection


/** ADC Prescaler Settings */
enum {
    ATM128_ADC_PRESCALE_2 = 0,
    ATM128_ADC_PRESCALE_2b,
    ATM128_ADC_PRESCALE_4,
    ATM128_ADC_PRESCALE_8,
    ATM128_ADC_PRESCALE_16,
    ATM128_ADC_PRESCALE_32,
    ATM128_ADC_PRESCALE_64,
    ATM128_ADC_PRESCALE_128,
};

/** ADC Multiplexer Selection Register */
typedef struct
{
    uint8_t aden  : 1;  //!< ADC Enable
    uint8_t adsc  : 1;  //!< ADC Start Conversion
    uint8_t adfr  : 1;  //!< ADC Free Running Select
    uint8_t adif  : 1;  //!< ADC Interrupt Flag
    uint8_t adie  : 1;  //!< ADC Interrupt Enable
    uint8_t adps  : 3;  //!< ADC Prescaler Select Bits
} ATm128ADCControl_t;

typedef ATm128ADCControl_t ATm128_ADCSRA_t;  //!< ADC Multiplexer Selection


typedef uint8_t ATm128_ADCH_t;         //!< ADC data register high
typedef uint8_t ATm128_ADCL_t;         //!< ADC data register low


#endif //_H_ATm128ADC_h

