/// $Id: HALADCM.nc,v 1.1.2.1 2005-03-24 08:47:40 husq Exp $

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

/// @author Hu Siquan <husq@xbow.com>

includes ATm128ADC;

module HALADCM 
{
  provides {
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
    IDLE = 0,
    SINGLE_CONVERSION = 1,
    CONTINUOUS_CONVERSION = 2,
    RESERVED,
  };
  
  enum {
    TOSH_ATM128_ADC_SIZE = 32,
  };
  
  ATm128ADCSelection_t val_admux;
  ATm128ADCControl_t val_adcsr;
  uint8_t ADCState;
  uint8_t curPort, reservedPort;

  command result_t StdControl.init() {
    atomic {
      curPort = 0xFF; // invalid port definition
      reservedPort = 0xFF;
      ADCState = IDLE;
    }
    dbg(DBG_BOOT, ("ADC initialized.\n"));

    // Enable ADC Interupts, 
    // Set Prescaler division factor to 64 
    atomic {
      val_adcsr.aden = ATM128_ADC_ENABLE_OFF;
      val_adcsr.adsc = ATM128_ADC_START_CONVERSION_OFF;  
      val_adcsr.adfr = ATM128_ADC_FREE_RUNNING_OFF; 
      val_adcsr.adif = ATM128_ADC_INT_FLAG_OFF;               
      val_adcsr.adie = ATM128_ADC_INT_ENABLE_ON;       
      val_adcsr.adps = ATM128_ADC_PRESCALE_64;
      call HPLADC.setControl(val_adcsr);
      val_admux.refs = ATM128_ADC_VREF_OFF;
	  val_admux.adlar = ATM128_ADC_RIGHT_ADJUST;
    }
    return SUCCESS;

  }

  command result_t StdControl.start() {

    return SUCCESS;
  }

  command result_t StdControl.stop() {

    // Disable ADC
    atomic {
      call HPLADC.disableADC();
    }
    return SUCCESS;
  }

  default async event result_t ATm128ADC.dataReady[uint8_t port](uint16_t data) {
    return FAIL; // ensures ADC is disabled if no handler
  }

  async event result_t HPLADC.dataReady(uint16_t data) {
    uint16_t doneValue = data;
    uint8_t donePort;
    result_t Result = SUCCESS;
    
    atomic donePort = curPort;
    dbg(DBG_ADC, "adc_tick: port %d with value %i \n", donePort, (int)data);
    Result = signal ATm128ADC.dataReady[donePort](doneValue);   
    atomic { 
    	if(ADCState==SINGLE_CONVERSION) {
    		call HPLADC.diableADC();
    	    ADCState = IDLE;
    	}
    	else if((ADCState==CONTINUOUS_CONVERSION) & (Result == FAIL) & (curPort == port)) {
    			   HPLADC.disableADC();
      			   HPLADC.setSingle();
                   ADCState = IDLE;
    		}
    	}
    return Result;    
  }
  

  inline  result_t startGet(uint8_t newState, uint8_t port) {

    result_t Result = SUCCESS;
    
    if (port > TOSH_ATM128_ADC_SIZE) {
      return FAIL;
    }

/// Only start conversion on IDLE mode or port is reserved. 
    atomic {
          if ((ADCState != IDLE) & ((ADCState != Reserved) |(reservedPort != port))) {
	/// Already a pending request on ADC
       Result = FAIL;
      }
      else {
	curPort = port;
	if (newState == SINGLE_CONVERSION) {
	  ADCState = SINGLE_CONVERSION;
	  call HPLADC.setSingle();
	}
	if (newState == CONTINUOUS_CONVERSION) {
	  ADCState = CONTINUOUS_CONVERSION;
	  call HPLADC.setContinous();	  
	}

	val_admux.mux = port;
    call HPLADC.setSelection(val_admux);
    call HPLADC.enableADC();
    call HPLADC.startConversion(); 
       }
    }
    // END atomic
    return Result;
  }

  async command result_t ATm128ADC.getData[uint8_t port]() {
    return startGet(SINGLE_CONVERSION, port);
  }

  async command result_t ATm128ADC.getContinuousData[uint8_t port]() {
    return startGet(CONTINUOUS_CONVERSION, port);
  }  
  
  async command result_t reserveADC[uint8_t port]() {
    result_t Result = SUCCESS;
  	if (ADCState == IDLE) {
  		ADCState = RESERVED;
  		reservedPort = port;
  		return SUCCESS;
  	}
  	else return FAIL;  	
  }
  
  async command result_t unreserve[uint8_t port]() {
    result_t Result = FAIL;
  	if (ADCState == RESERVED & reservedPort == port) {
  		ADCState = IDLE;
  		Result = SUCCESS;
  	}
  	else Result = FAIL;
  	return Result;  	
  }  
 
}

