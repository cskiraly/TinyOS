/// $Id: HPLADCM.nc,v 1.1.2.1 2005-02-03 01:16:07 mturon Exp $

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

module HPLADCM {
  provides {
    interface StdControl;
    interface ATm128ADC as ADC;
  }
}
implementation
{
  command result_t StdControl.init() {
      //call ADC.init();
  }

  command result_t StdControl.start() {
  }

  command result_t StdControl.stop() {
      ADC.disable();
  }


  //=== Direct read of HW registers. =================================
  async command ATm128ADCSettings_t ADC.getSettings() { 
      return *(ATm128ADCSettings_t*)&__inb_atomic(ADMUX); 
  }
  async command ATm128ADCControl_t ADC.getControl() { 
      return *(ATm128ADCControl_t*)&__inb_atomic(ADCSR); 
  }
  async command uint16_t ADC.getValue() { 
      return inw(ADCL); 
  }

  DEFINE_UNION_CAST(ADCSettings2int, ATm128ADCSettings_t, uint8_t);
  DEFINE_UNION_CAST(ADCControl2int, ATm128ADCControl_t, uint8_t);

  //=== Direct write of HW registers. ================================
  async command void ADC.setSettings( ATm128ADCControl_t x ) { 
      ADMUX = ADCSettings2int(x); 
  }
  async command void ADC.setControl( ATm128ADCControl_t x ) { 
      ADCSR = ADCControl2int(x); 
  }

  async command void enable()        { sbi(ADCSR, ADEN); }
  async command void disable()       { cbi(ADCSR, ADEN); }
  async command bool isEnabled()     {       
      return ADC.getControl().aden; 
  }

  async command void start()         { sbi(ADCSR, ADSC); }
  async command void stop()          { cbi(ADCSR, ADSC); }
  async command bool isStarted()     {
      return ADC.getControl().adsc; 
  }

  async command void setContinuous() { sbi(ADCSR, ADFR); }
  async command void setSingle()     { cbi(ADCSR, ADFR); }

  async command void reset()         { sbi(ADCSR, ADIF); }
  async command bool isComplete()    {
      return ADC.getControl().adif; 
  }


  default async event result_t ADC.dataReady(uint16_t done) { return SUCCESS; }

  TOSH_SIGNAL(SIG_ADC) {
      uint16_t data = ADC.getValue();
      data &= 0x3ff;
      ADC.reset();
      ADC.disable();
      __nesc_enable_interrupt();
      signal ADC.dataReady(data);
  }
}
