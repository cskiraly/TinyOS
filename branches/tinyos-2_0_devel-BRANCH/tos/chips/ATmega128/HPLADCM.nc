/// $Id: HPLADCM.nc,v 1.1.2.6 2005-07-11 17:25:32 idgay Exp $

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

#include "ATm128ADC.h"

module HPLADCM {
  provides interface HPLADC;
}
implementation
{

  //=== Direct read of HW registers. =================================
  async command ATm128ADCSelection_t HPLADC.getSelection() { 
      return *(ATm128ADCSelection_t*)&ADMUX; 
  }
  async command ATm128ADCControl_t HPLADC.getControl() { 
      return *(ATm128ADCControl_t*)&ADCSR; 
  }
  async command uint16_t HPLADC.getValue() { 
      return ADC; 
  }

  DEFINE_UNION_CAST(ADCSelection2int, ATm128ADCSelection_t, uint8_t);
  DEFINE_UNION_CAST(ADCControl2int, ATm128ADCControl_t, uint8_t);

  //=== Direct write of HW registers. ================================
  async command void HPLADC.setSelection( ATm128ADCSelection_t x ) { 
      ADMUX = ADCSelection2int(x); 
  }
  async command void HPLADC.setControl( ATm128ADCControl_t x ) { 
      ADCSR = ADCControl2int(x); 
  }

  async command void HPLADC.setPrescaler(uint8_t scale){
    ATm128ADCControl_t  current_val = call HPLADC.getControl(); 
    current_val.adps = scale;
    call HPLADC.setControl(current_val);
  }

  // power management routine should call following commands 
  async command void HPLADC.enableADC()        { SET_BIT(ADCSR, ADEN); }
  async command void HPLADC.disableADC()       { CLR_BIT(ADCSR, ADEN); }
  async command bool HPLADC.isEnabled()     {       
    return (call HPLADC.getControl()).aden; 
  }

  async command void HPLADC.startConversion()         { SET_BIT(ADCSR, ADSC); }
  async command void HPLADC.stopConversion()          { CLR_BIT(ADCSR, ADSC); }
  async command bool HPLADC.isStarted()     {
    return (call HPLADC.getControl()).adsc; 
  }
  
  async command void HPLADC.enableInterruption()        { SET_BIT(ADCSR, ADIE); }
  async command void HPLADC.disableInterruption()       { CLR_BIT(ADCSR, ADIE); }

  async command void HPLADC.setContinuous() { SET_BIT(ADCSR, ADFR); }
  async command void HPLADC.setSingle()     { CLR_BIT(ADCSR, ADFR); }

  async command void HPLADC.reset()         { SET_BIT(ADCSR, ADIF); }
  async command bool HPLADC.isComplete()    {
    return (call HPLADC.getControl()).adif; 
  }

  default async event void HPLADC.dataReady(uint16_t done) { }

  AVR_ATOMIC_HANDLER(SIG_ADC) {
      uint16_t data = call HPLADC.getValue();
      __nesc_enable_interrupt();
      signal HPLADC.dataReady(data);
  }
}
