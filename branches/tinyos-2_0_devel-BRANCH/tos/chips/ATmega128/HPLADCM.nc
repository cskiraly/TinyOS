/// $Id: HPLADCM.nc,v 1.1.2.3 2005-03-24 08:47:40 husq Exp $

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
/// @author Hu Siquan <husq@xbow.com>

module HPLADCM {
  provides {
    interface HPLADC as ADC;
  }
}
implementation
{

  //=== Direct read of HW registers. =================================
  async command ATm128ADCSelection_t ADC.getSelection() { 
      return *(ATm128ADCSelection_t*)&__inb_atomic(ADMUX); 
  }
  async command ATm128ADCControl_t ADC.getControl() { 
      return *(ATm128ADCControl_t*)&__inb_atomic(ADCSR); 
  }
  async command uint16_t ADC.getValue() { 
      return inw(ADCL); 
  }

  DEFINE_UNION_CAST(ADCSelection2int, ATm128ADCSelection_t, uint8_t);
  DEFINE_UNION_CAST(ADCControl2int, ATm128ADCControl_t, uint8_t);

  //=== Direct write of HW registers. ================================
  async command void ADC.setSelection( ATm128ADCSelection_t x ) { 
      //ADMUX = ADCSelection2int(x); 
      outp(ADCSelection2int(x),ADMUX);
  }
  async command void ADC.setControl( ATm128ADCControl_t x ) { 
      //ADCSR = ADCControl2int(x); 
      outp(ADCControl2int(x),ADCSR);
  }

  async command void setPrescaler(uint8_t scale){
    ATm128ADCControl_t  current_val = call HPLADC.getControl(); 
    current_val.adps = scale;
    call ADC.setControl(current_val);
  }

  // power management routine should call following commands 
  async command void enableADC()        { sbi(ADCSR, ADEN); }
  async command void disableADC()       { cbi(ADCSR, ADEN); }
  async command bool isEnabled()     {       
      return ADC.getControl().aden; 
  }

  async command void startConversion()         { sbi(ADCSR, ADSC); }
  async command void stopConversion()          { cbi(ADCSR, ADSC); }
  async command bool isStarted()     {
      return ADC.getControl().adsc; 
  }
  
  async command void enableInterruption()        { sbi(ADCSR, ADIE); }
  async command void disableInterruption()       { cbi(ADCSR, ADIE); }

  async command void setContinuous() { sbi(ADCSR, ADFR); }
  async command void setSingle()     { cbi(ADCSR, ADFR); }

  async command void reset()         { sbi(ADCSR, ADIF); }
  async command bool isComplete()    {
      return ADC.getControl().adif; 
  }

  default async event result_t ADC.dataReady(uint16_t done) { return SUCCESS; }

  TOSH_SIGNAL(SIG_ADC) {
      uint16_t data = ADC.getValue();
      data &= ATMEGA128_10BIT_ADC_MASK;
      __nesc_enable_interrupt();
      signal ADC.dataReady(data);
  }
}
