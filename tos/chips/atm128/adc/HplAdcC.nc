/// $Id: HplAdcC.nc,v 1.1.2.1 2005-08-13 01:16:31 idgay Exp $

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
/// @author David Gay

#include "Atm128Adc.h"

module HplAdcC {
  provides interface HplAdc;
}
implementation
{
  //=== Direct read of HW registers. =================================
  async command Atm128Admux_t HplAdc.getAdmux() { 
    return *(Atm128Admux_t*)&ADMUX; 
  }
  async command Atm128Adcsra_t HplAdc.getAdcsra() { 
    return *(Atm128Adcsra_t*)&ADCSRA; 
  }
  async command uint16_t HplAdc.getValue() { 
    return ADC; 
  }

  DEFINE_UNION_CAST(Admux2int, Atm128Admux_t, uint8_t);
  DEFINE_UNION_CAST(Adcsra2int, Atm128Adcsra_t, uint8_t);

  //=== Direct write of HW registers. ================================
  async command void HplAdc.setAdmux( Atm128Admux_t x ) { 
    ADMUX = Admux2int(x); 
  }
  async command void HplAdc.setAdcsra( Atm128Adcsra_t x ) { 
    ADCSRA = Adcsra2int(x); 
  }

  async command void HplAdc.setPrescaler(uint8_t scale){
    Atm128Adcsra_t  current_val = call HplAdc.getAdcsra(); 
    current_val.adif = FALSE;
    current_val.adps = scale;
    call HplAdc.setAdcsra(current_val);
  }

  // Individual bit manipulation. These all clear any pending A/D interrupt.
  // It's not clear these are that useful...
  async command void HplAdc.enableAdc() { SET_BIT(ADCSRA, ADEN); }
  async command void HplAdc.disableAdc() { CLR_BIT(ADCSRA, ADEN); }
  async command void HplAdc.enableInterruption() { SET_BIT(ADCSRA, ADIE); }
  async command void HplAdc.disableInterruption() { CLR_BIT(ADCSRA, ADIE); }
  async command void HplAdc.setContinuous() { SET_BIT(ADCSRA, ADFR); }
  async command void HplAdc.setSingle() { CLR_BIT(ADCSRA, ADFR); }
  async command void HplAdc.resetInterrupt() { SET_BIT(ADCSRA, ADIF); }
  async command void HplAdc.startConversion() { SET_BIT(ADCSRA, ADSC); }


  /* A/D status checks */
  async command bool HplAdc.isEnabled()     {       
    return (call HplAdc.getAdcsra()).aden; 
  }

  async command bool HplAdc.isStarted()     {
    return (call HplAdc.getAdcsra()).adsc; 
  }
  
  async command bool HplAdc.isComplete()    {
    return (call HplAdc.getAdcsra()).adif; 
  }

  /* A/D interrupt handlers. Signals dataReady event with interrupts enabled */
  AVR_ATOMIC_HANDLER(SIG_ADC) {
    uint16_t data = call HplAdc.getValue();
    
    __nesc_enable_interrupt();
    signal HplAdc.dataReady(data);
  }

  default async event void HplAdc.dataReady(uint16_t done) { }

  async command bool HplAdc.cancel() { 
    /* This is tricky */
    atomic
      {
	Atm128Adcsra_t oldSr = call HplAdc.getAdcsra(), newSr;

	/* To cancel a conversion, first turn off ADEN, then turn off
	   ADSC. We also cancel any pending interrupt.
	   Finally we reenable the ADC.
	*/
	newSr = oldSr;
	newSr.aden = FALSE;
	newSr.adif = TRUE; /* This clears a pending interrupt... */
	newSr.adie = FALSE; /* We don't want to start sampling again at the
			       next sleep */
	call HplAdc.setAdcsra(newSr);
	newSr.adsc = FALSE;
	call HplAdc.setAdcsra(newSr);
	newSr.aden = TRUE;
	call HplAdc.setAdcsra(newSr);

	return oldSr.adif || oldSr.adsc;
      }
  }
}
