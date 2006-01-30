/*
 * Copyright (c) 2004, Technische Universitaet Berlin
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
 * - Neither the name of the Technische Universitaet Berlin nor the names
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
 * - Revision -------------------------------------------------------------
 * $Revision: 1.1.2.2 $
 * $Date: 2006-01-30 17:44:12 $
 * @author: Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */
        
#include <Msp430Adc12.h>
interface HplAdc12
{
  /** Setting ADC12 Control Register ADC12CTL0 */
  async command void setCtl0(adc12ctl0_t control0); 
  
  /** Setting ADC12 Control Register ADC12CTL1 */
  async command void setCtl1(adc12ctl1_t control1);

  /** Returns the ADC12 Control Register ADC12CTL0 */
  async command adc12ctl0_t getCtl0(); 

  /** Returns the ADC12 Control Register ADC12CTL1 */
  async command adc12ctl1_t getCtl1(); 
  
  /** 
   * Setting the ADC12 Conversion Memory Control Register ADC12MCTLx.
   * @param index The register (the 'x' in ADC12MCTLx) [0..15] 
   */
  async command void setMCtl(uint8_t index, adc12memctl_t memControl); 
  
  /** 
   * Returns the ADC12 Conversion Memory Control Register ADC12MCTLx.
   * @param index The register (the 'x' in ADC12MCTLx) [0..15] 
   */
  async command adc12memctl_t getMCtl(uint8_t index); 

  /** 
   * Returns the ADC12 Conversion Memory Registers ADC12MEMx.
   * @param index The register (the 'x' in ADC12MEMx) [0..15] 
   */  
  async command uint16_t getMem(uint8_t index); 

  /** 
   * Setting the ADC12 Interrupt Enable Register, ADC12IE.
   * @param mask Bitmask (0 Interrupt disabled, 1 Interrupt enabled) 
   */
  async command void setIEFlags(uint16_t mask); 

  /** 
   * Returns the ADC12 Interrupt Enable Register, ADC12IE.
   */  
  async command uint16_t getIEFlags(); 
  
  /** 
   * Resets the ADC12 Interrupt Flag Register, ADC12IFG.
   */
  async command void resetIFGs(); 

  /** 
   * Returns the ADC12 Interrupt Flag Register, ADC12IFG.
   */  
  async command uint16_t getIFGs(); 

  /** 
   * Signals an ADC12MEMx overflow.
   */ 
  async event void memOverflow();

  /** 
   * Signals a Conversion time overflow.
   */ 
  async event void conversionTimeOverflow();

  /** 
   * Signals a conversion result. 
   * @param iv ADC12 interrupt vector value 0x6, 0x8, ... , 0x24
   */ 
  async event void conversionDone(uint16_t iv);

  /** 
   * The ADC12 BUSY flag.
   */ 
  async command bool isBusy();

  /* 
   * Note: setConversionMode and setSHT etc. require ENC-flag to be reset! 
   * (disableConversion)
   */

  /** 
   * Setting the Sample-and-hold time flags, SHT0x and SHT1x .
   * @param sht Sample-and-hold, top 4 bits = SHT1x, lower 4 bits = SHT0x
   */
  async command void setSHT(uint8_t sht);

  /** 
   * Setting the Multiple sample and conversion flag, MSC in ADC12CTL0. 
   */
  async command void setMSC();
 
  /** 
   * Resetting the Multiple sample and conversion flag, MSC in ADC12CTL0.
   */
  async command void resetMSC();

  /** 
   * Setting the REFON in ADC12CTL0. 
   */
  async command void setRefOn();

  /** 
   * Resetting the REFON in ADC12CTL0. 
   */
  async command void resetRefOn();

  /** 
   * Returns the REFON in ADC12CTL0. 
   */
  async command uint8_t getRefon();     // off if 0, else on

  /** 
   * Setting the reference generator voltage to 1.5V. 
   */
  async command void setRef1_5V();

  /** 
   * Setting the reference generator voltage to 2.5V. 
   */
  async command void setRef2_5V();

  /** 
   * Returns 1 if  reference generator voltage is 2.5V, 
   * returns 0 if  reference generator voltage is 1.5V, 
   */
  async command uint8_t isRef2_5V(); 
   
  /**
   * Enables a conversion (sets the ENC flag)
   */
  async command void enableConversion();

  /**
   * Disables a conversion (resets the ENC flag)
   */
  async command void disableConversion();

  /**
   * Starts a conversion.
   */
  async command void startConversion();

  /**
   * Stops a conversion.
   */  
  async command void stopConversion();
  
  /**
   * Switches the ADC12 off (ADC12ON flag).
   */  
  async command void adcOff();

  /**
   * Switches the ADC12 off (ADC12ON flag).
   */    
  async command void adcOn();
}

