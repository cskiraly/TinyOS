/* $Id: HALADCM.nc,v 1.1.2.2 2005-05-10 18:28:24 idgay Exp $
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
 *
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
/**
 * @author Jason Hill
 * @author David Gay
 * @author Philip Levis
 * @author Phil Buonadonna
 * @author Hu Siquan <husq@xbow.com>
 */

#include "ATm128ADC.h"

module HALADCM 
{
  provides {
    interface Init;
    interface StdControl;
    interface ATm128ADC[uint8_t port];		// The RAW ADC interface
  }
  uses {
    interface HPLADC;
  }
}
implementation
{  
  enum {
    IDLE,
    SINGLE_CONVERSION,
    CONTINUOUS_CONVERSION
  };
  
  uint8_t state;
  uint8_t curPort, reservedPort;

  command error_t Init.init() {
    atomic {
      curPort = 0xFF; // invalid port definition
      reservedPort = 0xFF;
      state = IDLE;
    }

    // Enable ADC Interupts, 
    // Set Prescaler division factor to 64 
    atomic {
      ATm128ADCControl_t adcsr;

      adcsr.aden = ATM128_ADC_ENABLE_OFF;
      adcsr.adsc = ATM128_ADC_START_CONVERSION_OFF;  
      adcsr.adfr = ATM128_ADC_FREE_RUNNING_OFF; 
      adcsr.adif = ATM128_ADC_INT_FLAG_OFF;               
      adcsr.adie = ATM128_ADC_INT_ENABLE_ON;       
      adcsr.adps = ATM128_ADC_PRESCALE_64;
      call HPLADC.setControl(adcsr);
    }
    return SUCCESS;

  }

  command error_t StdControl.start() {
    return SUCCESS;
  }

  command error_t StdControl.stop() {
    atomic call HPLADC.disableADC();

    return SUCCESS;
  }

  default async event error_t ATm128ADC.dataReady[uint8_t port](uint16_t data) {
    return FAIL; // ensures ADC is disabled if no handler
  }

  async event void HPLADC.dataReady(uint16_t data) {
    uint8_t donePort;
    error_t ok;
    
    atomic 
      {
	donePort = curPort;
	if (state == SINGLE_CONVERSION)
	  {
	    call HPLADC.disableADC();
	    state = IDLE;
	  }
      }
    ok = signal ATm128ADC.dataReady[donePort](data);   
    atomic
      if (state == CONTINUOUS_CONVERSION && ok != SUCCESS)
	{
	  call HPLADC.disableADC();
	  state = IDLE;
	}
  }

  inline error_t startGet(uint8_t newState, uint8_t port) {
    atomic
      {
	ATm128ADCSelection_t admux;

	if (state != IDLE)
	  return FAIL;

	curPort = port;
	state = newState;
	if (newState == SINGLE_CONVERSION)
	  call HPLADC.setSingle();
	else
	  call HPLADC.setContinuous();	  

	admux.refs = ATM128_ADC_VREF_OFF;
	admux.adlar = ATM128_ADC_RIGHT_ADJUST;
	admux.mux = port;
	call HPLADC.setSelection(admux);
	call HPLADC.enableADC();
	call HPLADC.startConversion(); 
      }
    return SUCCESS;
  }

  async command error_t ATm128ADC.getData[uint8_t port]() {
    return startGet(SINGLE_CONVERSION, port);
  }

  async command error_t ATm128ADC.getContinuousData[uint8_t port]() {
    return startGet(CONTINUOUS_CONVERSION, port);
  }  
}

