/// $Id: hardware.h,v 1.1.2.1 2005-02-09 08:04:20 mturon Exp $

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

/// @author Alan Broad   <abroad@xbow.com>
/// @author Matt Miller  <mmiller@xbow.com>
/// @author Martin Turon <mturon@xbow.com>

#ifndef TOSH_HARDWARE_H
#define TOSH_HARDWARE_H

#ifndef TOSH_HARDWARE_MICAZ
#define TOSH_HARDWARE_MICAZ
#endif // tosh hardware

#define TOSH_NEW_AVRLIBC // mica128 requires avrlibc v. 20021209 or greater
#include <atmega128hardware.h>
#include <CC2420Const.h>

// avrlibc may define ADC as a 16-bit register read.  
// This collides with the nesc ADC interface name
uint16_t inline getADC() {
  return inw(ADC);
}
#undef ADC

#define TOSH_CYCLE_TIME_NS 136

// each nop is 1 clock cycle
// 1 clock cycle on mica2 == 136ns
void inline TOSH_wait_250ns() {
      asm volatile  ("nop" ::);
      asm volatile  ("nop" ::);
}

void inline TOSH_uwait(int u_sec) {
    while (u_sec > 0) {
      asm volatile  ("nop" ::);
      asm volatile  ("nop" ::);
      asm volatile  ("nop" ::);
      asm volatile  ("nop" ::);
      asm volatile  ("nop" ::);
      asm volatile  ("nop" ::);
      asm volatile  ("nop" ::);
      asm volatile  ("nop" ::);
      u_sec--;
    }
}

// LED assignments
TOSH_ASSIGN_PIN(RED_LED, A, 2);
TOSH_ASSIGN_PIN(GREEN_LED, A, 1);
TOSH_ASSIGN_PIN(YELLOW_LED, A, 0);

TOSH_ASSIGN_PIN(SERIAL_ID, A, 4);
TOSH_ASSIGN_PIN(BAT_MON, A, 5);
TOSH_ASSIGN_PIN(THERM_PWR, A, 7);

// ChipCon control assignments

#define TOSH_CC_FIFOP_INT SIG_INTERRUPT6
// CC2420 Interrupt definition
#define CC2420_FIFOP_INT_ENABLE()  sbi(EIMSK , INT6)
#define CC2420_FIFOP_INT_DISABLE() cbi(EIMSK , INT6)
#define CC2420_FIFOP_INT_CLEAR()   sbi(EIFR, INTF6)
void inline CC2420_FIFOP_INT_MODE(bool LowToHigh) {
    sbi(EICRB,ISC61);		// edge mode
    if( LowToHigh)
	sbi(EICRB,ISC60);       // trigger on rising level
    else
	cbi(EICRB,ISC60);       // trigger on falling level
}



TOSH_ASSIGN_PIN(CC_RSTN, A, 6);      // chipcon reset
TOSH_ASSIGN_PIN(CC_VREN, A, 5);      // chipcon power enable
//TOSH_ASSIGN_PIN(CC_FIFOP1, D, 7);  // fifo interrupt
TOSH_ASSIGN_PIN(CC_FIFOP, E, 6);     // fifo interrupt
TOSH_ASSIGN_PIN(CC_FIFOP1, E, 6);    // fifo interrupt

TOSH_ASSIGN_PIN(CC_CCA, D, 6);	     // 
TOSH_ASSIGN_PIN(CC_SFD, D, 4);	     // chipcon packet arrival
TOSH_ASSIGN_PIN(CC_CS, B, 0);	     // chipcon enable
TOSH_ASSIGN_PIN(CC_FIFO, B, 7);	     // chipcon fifo

TOSH_ASSIGN_PIN(RADIO_CCA, D, 6);    //  

// Flash assignments
TOSH_ASSIGN_PIN(FLASH_SELECT, A, 3);
TOSH_ASSIGN_PIN(FLASH_CLK,  D, 5);
TOSH_ASSIGN_PIN(FLASH_OUT,  D, 3);
TOSH_ASSIGN_PIN(FLASH_IN,  D, 2);

// interrupt assignments
TOSH_ASSIGN_PIN(INT0, E, 4);
TOSH_ASSIGN_PIN(INT1, E, 5);
TOSH_ASSIGN_PIN(INT2, E, 6);
TOSH_ASSIGN_PIN(INT3, E, 7);

// spibus assignments 
TOSH_ASSIGN_PIN(MOSI,  B, 2);
TOSH_ASSIGN_PIN(MISO,  B, 3);
//TOSH_ASSIGN_PIN(SPI_OC1C, B, 7);
TOSH_ASSIGN_PIN(SPI_SCK,  B, 1);

// power control assignments
TOSH_ASSIGN_PIN(PW0, C, 0);
TOSH_ASSIGN_PIN(PW1, C, 1);
TOSH_ASSIGN_PIN(PW2, C, 2);
TOSH_ASSIGN_PIN(PW3, C, 3);
TOSH_ASSIGN_PIN(PW4, C, 4);
TOSH_ASSIGN_PIN(PW5, C, 5);
TOSH_ASSIGN_PIN(PW6, C, 6);
TOSH_ASSIGN_PIN(PW7, C, 7);

// i2c bus assignments
TOSH_ASSIGN_PIN(I2C_BUS1_SCL, D, 0);
TOSH_ASSIGN_PIN(I2C_BUS1_SDA, D, 1);

// uart assignments
TOSH_ASSIGN_PIN(UART_RXD0, E, 0);
TOSH_ASSIGN_PIN(UART_TXD0, E, 1);
TOSH_ASSIGN_PIN(UART_XCK0, E, 2);
TOSH_ASSIGN_PIN(AC_NEG, E, 3);        // RFID Reader Red LED

TOSH_ASSIGN_PIN(UART_RXD1, D, 2);
TOSH_ASSIGN_PIN(UART_TXD1, D, 3);
TOSH_ASSIGN_PIN(UART_XCK1, D, 5);

void TOSH_SET_PIN_DIRECTIONS(void)
{
// LED pins
  TOSH_MAKE_RED_LED_OUTPUT();
  TOSH_MAKE_YELLOW_LED_OUTPUT();
  TOSH_MAKE_GREEN_LED_OUTPUT();
      
  TOSH_MAKE_PW7_OUTPUT();
  TOSH_MAKE_PW6_OUTPUT();
  TOSH_MAKE_PW5_OUTPUT();
  TOSH_MAKE_PW4_OUTPUT();
  TOSH_MAKE_PW3_OUTPUT(); 
  TOSH_MAKE_PW2_OUTPUT();
  TOSH_MAKE_PW1_OUTPUT();
  TOSH_MAKE_PW0_OUTPUT();

// CC2420 pins  
  TOSH_MAKE_MISO_INPUT();
  TOSH_MAKE_MOSI_OUTPUT();
  TOSH_MAKE_SPI_SCK_OUTPUT();
  TOSH_MAKE_CC_RSTN_OUTPUT();    
  TOSH_MAKE_CC_VREN_OUTPUT();
  TOSH_MAKE_CC_CS_INPUT(); 
  TOSH_MAKE_CC_FIFOP1_INPUT();    
  TOSH_MAKE_CC_CCA_INPUT();
  TOSH_MAKE_CC_SFD_INPUT();
  TOSH_MAKE_CC_FIFO_INPUT(); 

  TOSH_MAKE_RADIO_CCA_INPUT();


  TOSH_MAKE_SERIAL_ID_INPUT();
  TOSH_CLR_SERIAL_ID_PIN();         // Prevent sourcing current

  TOSH_MAKE_FLASH_SELECT_OUTPUT();
  TOSH_MAKE_FLASH_OUT_OUTPUT();
  TOSH_MAKE_FLASH_CLK_OUTPUT();
  TOSH_SET_FLASH_SELECT_PIN();
    
  TOSH_SET_RED_LED_PIN();
  TOSH_SET_YELLOW_LED_PIN();
  TOSH_SET_GREEN_LED_PIN();

}

enum {
  TOSH_ADC_PORTMAPSIZE = 12
};

enum 
{
//  TOSH_ACTUAL_CC_RSSI_PORT = 0,
  TOSH_ACTUAL_VOLTAGE_PORT = 30,    // map to internal BG ref
  TOSH_ACTUAL_BANDGAP_PORT = 30,    // 1.23 Fixed bandgap reference
  TOSH_ACTUAL_GND_PORT     = 31     // GND 
};

enum 
{
 // TOS_ADC_CC_RSSI_PORT = 0,
  TOS_ADC_VOLTAGE_PORT = 7,
  TOS_ADC_BANDGAP_PORT = 10,
  TOS_ADC_GND_PORT     = 11
};


#endif //TOSH_HARDWARE_H




