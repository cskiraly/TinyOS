/* -*- mode:c++; indent-tabs-mode: nil -*-
 * "Copyright (c) 2005 Stanford University. All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and
 * its documentation for any purpose, without fee, and without written
 * agreement is hereby granted, provided that the above copyright
 * notice, the following two paragraphs and the author appear in all
 * copies of this software.
 * 
 * IN NO EVENT SHALL STANFORD UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES
 * ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN
 * IF STANFORD UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
 * DAMAGE.
 * 
 * STANFORD UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE
 * PROVIDED HEREUNDER IS ON AN "AS IS" BASIS, AND STANFORD UNIVERSITY
 * HAS NO OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES,
 * ENHANCEMENTS, OR MODIFICATIONS."
 *
 */

/*
 * Copyright (c) 2006, Technische Universitaet Berlin
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
 * - Neither the name of the Technische Universitat Berlin nor the names
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
 */

/**
 * Implementation of TEP 112 (Microcontroller Power Management) for
 * the MSP430. Code for low power calculation copied from older
 * msp430hardware.h by Vlado Handziski, Joe Polastre, and Cory Sharp.
 *
 * Adapted for eyesIFX platform to perform SMCLK switching (using the stable 1MHz
 * XT2 as SMCLK source makes communication reliable.)
 *
 * @author Philip Levis
 * @author Vlado Handziski
 * @author Joe Polastre
 * @author Cory Sharp
 * @author Andreas Koepke
 * @date   October 26, 2005
 * @see  Please refer to TEP 112 for more information about this component and its
 *          intended use.
 *
 */

module McuSleepC {
  provides {
    interface McuSleep;
    interface McuPowerState;
    interface CrystalControl;
  }
  uses {
    interface McuPowerOverride;
  }
}
implementation {
  bool dirty = TRUE;
  mcu_power_t powerState = MSP430_POWER_ACTIVE;

  /* Note that the power values are maintained in an order
   * based on their active components, NOT on their values.
   * Look at atm128hardware.h and page 42 of the ATmeg128
   * manual (figure 17).*/
  // NOTE: This table should be in progmem.
  const uint16_t msp430PowerBits[MSP430_POWER_LPM4 + 1] = {
    0,                                       // ACTIVE
    SR_CPUOFF,                               // LPM0
    SR_SCG0+SR_CPUOFF,                       // LPM1
    SR_SCG1+SR_CPUOFF,                       // LPM2
    SR_SCG1+SR_SCG0+SR_CPUOFF,               // LPM3
    SR_SCG1+SR_SCG0+SR_OSCOFF+SR_CPUOFF,     // LPM4
  };
    
  mcu_power_t getPowerState() {
    mcu_power_t pState = MSP430_POWER_LPM3;
    // TimerA, USART0, USART1 check
    if ((((TACCTL0 & CCIE) ||
	  (TACCTL1 & CCIE) ||
	  (TACCTL2 & CCIE)) &&
	 ((TACTL & TASSEL_3) == TASSEL_2)) ||
	((ME1 & (UTXE0 | URXE0)) && (U0TCTL & SSEL1)) ||
	((ME2 & (UTXE1 | URXE1)) && (U1TCTL & SSEL1))
#ifdef __msp430_have_usart0_with_i2c
	 // registers end in "nr" to prevent nesC race condition detection
	 || ((U0CTLnr & I2CEN) && (I2CTCTLnr & SSEL1) &&
	     (I2CDCTLnr & I2CBUSY) && (U0CTLnr & SYNC) && (U0CTLnr & I2C))
#endif
	)
      pState = MSP430_POWER_LPM1;
    
    // ADC12 check: 
    if (ADC12CTL0 & ADC12ON){
      if (ADC12CTL1 & ADC12SSEL_2){
        // sample or conversion operation with MCLK or SMCLK
        if (ADC12CTL1 & ADC12SSEL_1)
          pState = MSP430_POWER_LPM1;
        else
          pState = MSP430_POWER_ACTIVE;
      } else if ((ADC12CTL1 & SHS0) && ((TACTL & TASSEL_3) == TASSEL_2)){
        // Timer A is used as sample-and-hold source and SMCLK sources Timer A
        // (Timer A interrupts are always disabled when it is used by the 
        // ADC subsystem, that's why the Timer check above is not enough)
	      pState = MSP430_POWER_LPM1;
      }
    }
    
    return pState;
  }
  
  void computePowerState() {
    powerState = mcombine(getPowerState(),
			  call McuPowerOverride.lowestState());
  }
  
  async command void McuSleep.sleep() {
    uint16_t temp;
    if (dirty) {
      computePowerState();
      //dirty = 0;
    }
    if((powerState == MSP430_POWER_LPM3) && (!BCSCTL1 & XT2OFF)
       && (signal CrystalControl.stop() == SUCCESS)) {
        BCSCTL1 |=  XT2OFF;
        BCSCTL2 = DIVS1;
    };
    temp = msp430PowerBits[powerState] | SR_GIE;
    __asm__ __volatile__( "bis  %0, r2" : : "m" (temp) );
    __nesc_disable_interrupt();
  }

  async command void McuPowerState.update() {
    atomic dirty = 1;
  }
  
  async command void CrystalControl.stable() {
      if(BCSCTL1 & XT2OFF) {
          BCSCTL1 &= ~XT2OFF;
          BCSCTL2 = SELS;
      }
  }
  
 default async command mcu_power_t McuPowerOverride.lowestState() {
   return MSP430_POWER_LPM4;
 }
 default async event error_t CrystalControl.stop() {
     return SUCCESS;
 }
  default async event void CrystalControl.start() {
 }
}
