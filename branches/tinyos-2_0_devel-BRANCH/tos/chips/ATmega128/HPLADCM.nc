/// $Id: HPLADCM.nc,v 1.1.2.7 2005-07-11 21:56:42 idgay Exp $

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

#include "ATm128ADC.h"

module HPLADCM {
  provides interface HPLADC;
}
implementation
{
  //=== Direct read of HW registers. =================================
  async command ATm128Admux_t HPLADC.getAdmux() { 
    return *(ATm128Admux_t*)&ADMUX; 
  }
  async command ATm128Adcsra_t HPLADC.getAdcsra() { 
    return *(ATm128Adcsra_t*)&ADCSRA; 
  }
  async command uint16_t HPLADC.getValue() { 
    return ADC; 
  }

  DEFINE_UNION_CAST(Admux2int, ATm128Admux_t, uint8_t);
  DEFINE_UNION_CAST(Adcsra2int, ATm128Adcsra_t, uint8_t);

  //=== Direct write of HW registers. ================================
  async command void HPLADC.setAdmux( ATm128Admux_t x ) { 
    ADMUX = Admux2int(x); 
  }
  async command void HPLADC.setAdcsra( ATm128Adcsra_t x ) { 
    ADCSRA = Adcsra2int(x); 
  }

  async command void HPLADC.setPrescaler(uint8_t scale){
    ATm128Adcsra_t  current_val = call HPLADC.getAdcsra(); 
    current_val.adif = FALSE;
    current_val.adps = scale;
    call HPLADC.setAdcsra(current_val);
  }

  // Individual bit manipulation. These all clear any pending A/D interrupt.
  // It's not clear these are that useful...
  async command void HPLADC.enableADC() { SET_BIT(ADCSRA, ADEN); }
  async command void HPLADC.disableADC() { CLR_BIT(ADCSRA, ADEN); }
  async command void HPLADC.enableInterruption() { SET_BIT(ADCSRA, ADIE); }
  async command void HPLADC.disableInterruption() { CLR_BIT(ADCSRA, ADIE); }
  async command void HPLADC.setContinuous() { SET_BIT(ADCSRA, ADFR); }
  async command void HPLADC.setSingle() { CLR_BIT(ADCSRA, ADFR); }
  async command void HPLADC.resetInterrupt() { SET_BIT(ADCSRA, ADIF); }
  async command void HPLADC.startConversion() { SET_BIT(ADCSRA, ADSC); }


  /* A/D status checks */
  async command bool HPLADC.isEnabled()     {       
    return (call HPLADC.getAdcsra()).aden; 
  }

  async command bool HPLADC.isStarted()     {
    return (call HPLADC.getAdcsra()).adsc; 
  }
  
  async command bool HPLADC.isComplete()    {
    return (call HPLADC.getAdcsra()).adif; 
  }

  /* A/D interrupt handlers. Signals dataReady event with interrupts enabled */
  AVR_ATOMIC_HANDLER(SIG_ADC) {
    uint16_t data = call HPLADC.getValue();
    
    __nesc_enable_interrupt();
    signal HPLADC.dataReady(data);
  }

  default async event void HPLADC.dataReady(uint16_t done) { }

  async command bool HPLADC.cancel() { 
    /* This is tricky */
    atomic
      {
	ATm128Adcsra_t oldSr = call HPLADC.getAdcsra(), newSr;

	/* To cancel a conversion, first turn off ADEN, then turn off
	   ADSC. We also cancel any pending interrupt.
	   Finally we reenable the ADC.
	*/
	newSr = oldSr;
	newSr.aden = FALSE;
	newSr.adif = TRUE; /* This clears a pending interrupt... */
	newSr.adie = FALSE; /* We don't want to start sampling again at the
			       next sleep */
	call HPLADC.setAdcsra(newSr);
	newSr.adsc = FALSE;
	call HPLADC.setAdcsra(newSr);
	newSr.aden = TRUE;
	call HPLADC.setAdcsra(newSr);

	return oldSr.adif || oldSr.adsc;
      }
  }
}
