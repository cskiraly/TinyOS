/**                                                                     tab:4
 *  IMPORTANT: READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.  By
 *  downloading, copying, installing or using the software you agree to
 *  this license.  If you do not agree to this license, do not download,
 *  install, copy or use the software.
 *
 *  Copyright (c) 2004-2005 Crossbow Technology, Inc.
 *  Copyright (c) 2002-2003 Intel Corporation.
 *  Copyright (c) 2000-2003 The Regents of the University  of California.    
 *  All rights reserved.
 *
 *  Permission to use, copy, modify, and distribute this software and its
 *  documentation for any purpose, without fee, and without written
 *  agreement is hereby granted, provided that the above copyright
 *  notice, the (updated) modification history and the author appear in
 *  all copies of this source code.
 *
 *  Permission is also granted to distribute this software under the
 *  standard BSD license as contained in the TinyOS distribution.
 *
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 *  ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 *  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 *  PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE INTEL OR ITS
 *  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 *  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 *  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 *  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 *  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 *  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 *  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 *  @author Jason Hill, Philip Levis, Nelson Lee, David Gay
 *  @author Alan Broad <abroad@xbow.com>
 *  @author Matt Miller <mmiller@xbow.com>
 *  @author Martin Turon <mturon@xbow.com>
 *
 *  $Id: hardware.h,v 1.1.2.2 2005-05-10 18:13:46 idgay Exp $
 */

#ifndef TOSH_HARDWARE_H
#define TOSH_HARDWARE_H

#ifndef TOSH_HARDWARE_MICA2
#define TOSH_HARDWARE_MICA2
#endif // tosh hardware

#define TOSH_NEW_AVRLIBC // mica128 requires avrlibc v. 20021209 or greater
#include <atmega128hardware.h>

// LED assignments
TOSH_ASSIGN_PIN(RED_LED, A, 2);
TOSH_ASSIGN_PIN(GREEN_LED, A, 1);
TOSH_ASSIGN_PIN(YELLOW_LED, A, 0);

TOSH_ASSIGN_PIN(SERIAL_ID, A, 4);
TOSH_ASSIGN_PIN(BAT_MON, A, 5);
TOSH_ASSIGN_PIN(THERM_PWR, A, 7);

// ChipCon control assignments
TOSH_ASSIGN_PIN(CC_CHP_OUT, A, 6); // chipcon CHP_OUT
TOSH_ASSIGN_PIN(CC_PDATA, D, 7);  // chipcon PDATA 
TOSH_ASSIGN_PIN(CC_PCLK, D, 6);	  // chipcon PCLK
TOSH_ASSIGN_PIN(CC_PALE, D, 4);	  // chipcon PALE

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
TOSH_ASSIGN_PIN(SPI_OC1C, B, 7);
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
TOSH_ASSIGN_PIN(UART_XCK0, E, 2)

TOSH_ASSIGN_PIN(UART_RXD1, D, 2);
TOSH_ASSIGN_PIN(UART_TXD1, D, 3);
TOSH_ASSIGN_PIN(UART_XCK1, D, 5);

// A/D channels
enum {
  CHANNEL_RSSI       = 0,
  CHANNEL_THERMISTOR = 1,    // normally unpopulated
  CHANNEL_BATTERY    = 7,
  CHANNEL_BANDGAP    = 30,   // 1.23V Fixed bandgap reference
  CHANNEL_GND        = 31
};

void TOSH_SET_PIN_DIRECTIONS(void)
{
    TOSH_MAKE_CC_CHP_OUT_INPUT();	// modified for mica2 series
    
    TOSH_MAKE_PW7_OUTPUT();
    TOSH_MAKE_PW6_OUTPUT();
    TOSH_MAKE_PW5_OUTPUT();
    TOSH_MAKE_PW4_OUTPUT();
    TOSH_MAKE_PW3_OUTPUT(); 
    TOSH_MAKE_PW2_OUTPUT();
    TOSH_MAKE_PW1_OUTPUT();
    TOSH_MAKE_PW0_OUTPUT();
    
    TOSH_MAKE_CC_PALE_OUTPUT();    
    TOSH_MAKE_CC_PDATA_OUTPUT();
    TOSH_MAKE_CC_PCLK_OUTPUT();
    TOSH_MAKE_MISO_INPUT();
    TOSH_MAKE_SPI_OC1C_INPUT();
    
    TOSH_MAKE_SERIAL_ID_INPUT();
    TOSH_CLR_SERIAL_ID_PIN();  // Prevent sourcing current
}

enum 
{
    TOSH_ACTUAL_CC_RSSI_PORT = 0,
    TOSH_ACTUAL_VOLTAGE_PORT = 7,
    TOSH_ACTUAL_BANDGAP_PORT = 30,  // 1.23 Fixed bandgap reference
    TOSH_ACTUAL_GND_PORT     = 31   // GND 
};

enum 
{
    TOS_ADC_CC_RSSI_PORT = 0,
    TOS_ADC_VOLTAGE_PORT = 7,
    TOS_ADC_BANDGAP_PORT = 10,
    TOS_ADC_GND_PORT     = 11
};

void inline uwait(int u_sec) {
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

#endif //TOSH_HARDWARE_H
