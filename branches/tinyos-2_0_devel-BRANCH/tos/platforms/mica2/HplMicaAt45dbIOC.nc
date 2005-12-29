// $Id: HplMicaAt45dbIOC.nc,v 1.1.2.1 2005-12-29 18:12:36 idgay Exp $

/*									tab:4
 * "Copyright (c) 2000-2003 The Regents of the University  of California.  
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
 *
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
/*
 *
 * Authors:		Jason Hill, David Gay, Philip Levis
 * Date last modified:  6/25/02
 *
 */

/**
 * Low level hardware access to the onboard EEPROM (well, Flash actually)
 * @author Jason Hill
 * @author David Gay
 * @author Philip Levis
 */

module HPLFlash {
  provides {
    interface StdControl as FlashControl;
    interface FastSPI as FlashSPI;
    interface SlavePin as FlashSelect;
    interface Resource as FlashIdle;
    command bool getCompareStatus();
  }
}
implementation
{
  // We use SPI mode 0 (clock low at select time)

  command result_t FlashControl.init() {
    TOSH_MAKE_FLASH_SELECT_OUTPUT();
    TOSH_SET_FLASH_SELECT_PIN();
    TOSH_CLR_FLASH_CLK_PIN();
    TOSH_MAKE_FLASH_CLK_OUTPUT();
    TOSH_SET_FLASH_OUT_PIN();
    TOSH_MAKE_FLASH_OUT_OUTPUT();
    TOSH_CLR_FLASH_IN_PIN();
    TOSH_MAKE_FLASH_IN_INPUT();

    cbi(EIMSK, 2); // disable flash in interrupt
    EICRA |= 0x30; // make flash in a rising-edge interrupt

    return SUCCESS;
  }

  command result_t FlashControl.start() {
    return SUCCESS;
  }

  command result_t FlashControl.stop() {
    return SUCCESS;
  }

  // The flash select is not shared on mica2, mica2dot
  async command result_t FlashSelect.low() {
    TOSH_CLR_FLASH_CLK_PIN(); // ensure SPI mode 0
    TOSH_CLR_FLASH_SELECT_PIN();
    return SUCCESS;
  }

  task void sigHigh() {
    signal FlashSelect.notifyHigh();
  }

  async command result_t FlashSelect.high(bool needEvent) {
    TOSH_SET_FLASH_SELECT_PIN();
    if (needEvent)
      post sigHigh();
    return SUCCESS;
  }
  
#define BITINIT \
  uint8_t clrClkAndData = inp(PORTD) & ~0x28

#define BIT(n) \
	outp(clrClkAndData, PORTD); \
	asm __volatile__ \
        (  "sbrc %2," #n "\n" \
	 "\tsbi 18,3\n" \
	 "\tsbi 18,5\n" \
	 "\tsbic 16,2\n" \
	 "\tori %0,1<<" #n "\n" \
	 : "=d" (spiIn) : "0" (spiIn), "r" (spiOut))

  async command uint8_t FlashSPI.txByte(uint8_t spiOut) {
    uint8_t spiIn = 0;

    // This atomic ensures integrity at the hardware level...
    atomic
      {
	BITINIT;

	BIT(7);
	BIT(6);
	BIT(5);
	BIT(4);
	BIT(3);
	BIT(2);
	BIT(1);
	BIT(0);
      }

    return spiIn;
  }

  /**
   * Check FLASH status byte.
   * @return TRUE if the flash is ready, FALSE if not.
   *   In the TRUE case, the full status byte may not have been
   *   read out of the flash, in the FALSE case it is fully read out.
   */

  task void avail() {
    signal FlashIdle.available();
  }

  command result_t FlashIdle.wait() {
    result_t waits;

    // Setup interrupt on rising edge of flash in
    atomic
      {
	EIFR = 1 << 2; // clear any pending interrupt
	sbi(EIMSK, 2); // enable interrupt
	TOSH_CLR_FLASH_CLK_PIN();
	// We need to wait at least 2 cycles here (because of the signal
	// acquisition delay). It's also good to wait a few microseconds
	// to get the fast ("FAIL") exit from wait (reads are twice as fast
	// with a 2us delay...)
	TOSH_uwait(2);

	if (TOSH_READ_FLASH_IN_PIN())
	  {
	    // already high
	    cbi(EIMSK, 2);
	    waits = FAIL;
	  }
	else
	  waits = SUCCESS;
      }
    return waits;
  }


  TOSH_SIGNAL(SIG_INTERRUPT2) {
    cbi(EIMSK, 2); // disable interrupt
    post avail();
  }

  command bool getCompareStatus() {
    TOSH_SET_FLASH_CLK_PIN();
    TOSH_CLR_FLASH_CLK_PIN();
    // Wait for compare value to propagate
    asm volatile("nop");
    asm volatile("nop");
    return !TOSH_READ_FLASH_IN_PIN();
  }

  default event result_t FlashIdle.available() {
    return SUCCESS;
  }
}
