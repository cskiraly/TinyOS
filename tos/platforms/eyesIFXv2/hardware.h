/*
 * Copyright (c) 2004, Technische Universität Berlin
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright notice,
 *   this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the distribution.
 * - Neither the name of the Technische Universität Berlin nor the names
 *   of its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA,
 * OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * $Id: hardware.h,v 1.1.2.1 2005-03-16 19:01:07 vlahan Exp $
 *
 */

#ifndef TOSH_HARDWARE_EYESIFXV2
#define TOSH_HARDWARE_EYESIFXV2

#include "msp430hardware.h"
//#include "MSP430ADC12.h"

// LED assignments
TOSH_ASSIGN_PIN(RED_LED, 5, 0); // Compatibility with the mica2
TOSH_ASSIGN_PIN(GREEN_LED, 5, 1);
TOSH_ASSIGN_PIN(YELLOW_LED, 5, 2);

TOSH_ASSIGN_PIN(LED0, 5, 0);
TOSH_ASSIGN_PIN(LED1, 5, 1);
TOSH_ASSIGN_PIN(LED2, 5, 2);
TOSH_ASSIGN_PIN(LED3, 5, 3);

// TDA5250 assignments
TOSH_ASSIGN_PIN(TDA_PWDDD, 1, 0); // TDA PWDDD
TOSH_ASSIGN_PIN(TDA_DATA, 1, 1);  // TDA DATA (timerA, CCI0A)
TOSH_ASSIGN_PIN(TDA_TXRX, 1, 4);  // TDA TX/RX
TOSH_ASSIGN_PIN(TDA_BUSM, 1, 5);  // TDA BUSM
TOSH_ASSIGN_PIN(TDA_ENTDA, 1, 6); // TDA EN_TDA

// USART0 assignments
TOSH_ASSIGN_PIN(SIMO0, 3, 1); // SIMO (MSP) -> BUSDATA (TDA5250)
TOSH_ASSIGN_PIN(SOMI0, 3, 2); // SOMI (MSP) -> BUSDATA (TDA5250)
TOSH_ASSIGN_PIN(UCLK0, 3, 3); // UCLK (MSP) -> BUSCLK (TDA5250)
TOSH_ASSIGN_PIN(UTXD0, 3, 4);   // USART0 -> data1 (TDA5250)
TOSH_ASSIGN_PIN(URXD0, 3, 5);   // USART0 -> data1 (TDA5250)

// USART1 assignments

TOSH_ASSIGN_PIN(UTXD1, 3, 6);   // USART1 -> USB
TOSH_ASSIGN_PIN(URXD1, 3, 7);   // USART1 -> USB
void TOSH_SEL_SIMO1_IOFUNC() { }
void TOSH_SEL_SOMI1_IOFUNC() { }
void TOSH_SEL_UCLK1_IOFUNC() { }
void TOSH_SEL_SIMO1_MODFUNC() { }
void TOSH_SEL_SOMI1_MODFUNC() { }
void TOSH_SEL_UCLK1_MODFUNC() { }

// Sensor assignments
TOSH_ASSIGN_PIN(RSSI, 6, 3);
TOSH_ASSIGN_PIN(TEMP, 6, 0);
TOSH_ASSIGN_PIN(LIGHT, 6, 2);
TOSH_ASSIGN_PIN(VREF, 6, 7);
TOSH_ASSIGN_PIN(B0, 6, 4);
TOSH_ASSIGN_PIN(B1, 6, 5);
TOSH_ASSIGN_PIN(B2, 6, 7);
TOSH_ASSIGN_PIN(B3, 6, 6);
TOSH_ASSIGN_PIN(B4, 6, 1);


// Potentiometer
TOSH_ASSIGN_PIN(POT_EN, 2, 4);
TOSH_ASSIGN_PIN(POT_SD, 2, 3);

// TimerA output
TOSH_ASSIGN_PIN(TIMERA0, 1, 1); //2,7
TOSH_ASSIGN_PIN(TIMERA1, 1, 2);
TOSH_ASSIGN_PIN(TIMERA2, 1, 3);

// TimerB output
TOSH_ASSIGN_PIN(TIMERB0, 4, 0);
TOSH_ASSIGN_PIN(TIMERB1, 4, 1);
TOSH_ASSIGN_PIN(TIMERB2, 4, 2);

// SMCLK output
TOSH_ASSIGN_PIN(SMCLK, 5, 5); //2,7

// ACLK output
TOSH_ASSIGN_PIN(ACLK, 2, 0);

// Flash
TOSH_ASSIGN_PIN(FLASH_CS, 1, 7);


void TOSH_SET_PIN_DIRECTIONS(void)
{

  // reset all of the ports to be input and using i/o functionality
  P1SEL = 0;
  P2SEL = 0;
  P3SEL = 0;
  P4SEL = 0;
  P5SEL = 0;
  P6SEL = 0;
  P1DIR = 0;
  P2DIR = 0;
  P3DIR = 0;
  P4DIR = 0;
  P5DIR = 0;
  P6DIR = 0;


  TOSH_CLR_LED0_PIN();
  TOSH_MAKE_LED0_OUTPUT();

  TOSH_CLR_LED1_PIN();
  TOSH_MAKE_LED1_OUTPUT();

  TOSH_CLR_LED2_PIN();
  TOSH_MAKE_LED2_OUTPUT();

  TOSH_CLR_LED3_PIN();
  TOSH_MAKE_LED3_OUTPUT();

  TOSH_SET_FLASH_CS_PIN();
  TOSH_MAKE_FLASH_CS_OUTPUT();

  // start radio HW now
  TOSH_SET_TDA_PWDDD_PIN();
  TOSH_MAKE_TDA_PWDDD_OUTPUT();
}

#define RSSI_ADC12_STANDARD_SETTINGS   SET_ADC12_STANDARD_SETTINGS(INPUT_CHANNEL_A3, \
                                                                   REFERENCE_VREFplus_AVss, \
                                                                   SAMPLE_HOLD_4_CYCLES, \
                                                                   REFVOLT_LEVEL_1_5)
#define PHOTO_ADC12_STANDARD_SETTINGS  SET_ADC12_STANDARD_SETTINGS(INPUT_CHANNEL_A2, \
                                                                   REFERENCE_VREFplus_AVss, \
                                                                   SAMPLE_HOLD_64_CYCLES, \
                                                                   REFVOLT_LEVEL_1_5)
#define TEMP_ADC12_STANDARD_SETTINGS   SET_ADC12_STANDARD_SETTINGS(INPUT_CHANNEL_A0, \
                                                                   REFERENCE_AVcc_AVss, \
                                                                   SAMPLE_HOLD_4_CYCLES, \
                                                                   REFVOLT_LEVEL_1_5)

#define RSSI_ADC12_ADVANCED_SETTINGS   SET_ADC12_ADVANCED_SETTINGS(INPUT_CHANNEL_A3, \
                                                                   REFERENCE_VREFplus_AVss, \
                                                                   SAMPLE_HOLD_4_CYCLES, \
                                                                   CLOCK_SOURCE_SMCLK, \
                                                                   CLOCK_DIV_1, \
                                                                   HOLDSOURCE_TIMERB_OUT0,\
                                                                   REFVOLT_LEVEL_1_5)
#define PHOTO_ADC12_ADVANCED_SETTINGS  SET_ADC12_ADVANCED_SETTINGS(INPUT_CHANNEL_A2, \
                                                                   REFERENCE_VREFplus_AVss, \
                                                                   SAMPLE_HOLD_64_CYCLES, \
                                                                   CLOCK_SOURCE_SMCLK, \
                                                                   CLOCK_DIV_1, \
                                                                   HOLDSOURCE_TIMERB_OUT0,\
                                                                   REFVOLT_LEVEL_1_5)
#define TEMP_ADC12_ADVANCED_SETTINGS   SET_ADC12_ADVANCED_SETTINGS(INPUT_CHANNEL_A0, \
                                                                   REFERENCE_AVcc_AVss, \
                                                                   SAMPLE_HOLD_4_CYCLES, \
                                                                   CLOCK_SOURCE_SMCLK, \
                                                                   CLOCK_DIV_1, \
                                                                   HOLDSOURCE_TIMERB_OUT0, \
                                                                   REFVOLT_LEVEL_1_5)
#endif //TOSH_HARDWARE_EYESIFXV2
