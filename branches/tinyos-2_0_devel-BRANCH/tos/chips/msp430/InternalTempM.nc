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
 * - Revision -------------------------------------------------------------
 * $Revision: 1.1.2.1 $
 * $Date: 2005-02-09 14:41:48 $
 * @author Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */
includes ADCHIL;
module InternalTempM {
  provides {
    interface StdControl;
    interface ADCSingle;
    interface ADCMultiple;
  }
  uses {
    interface ADCControl;
    interface MSP430ADC12Single;
    interface MSP430ADC12Multiple;
  }
}
implementation {
  norace bool contMode;

  command result_t StdControl.init() {
    contMode = FALSE;
    return SUCCESS;
  }
  
  command result_t StdControl.start() {
   result_t ok1, ok2;
   
   ok1 = call ADCControl.init();
   ok2 = call ADCControl.bindPort(TOS_ADC_INTERNAL_TEMP_PORT, 
                                  TOSH_ACTUAL_ADC_INTERNAL_TEMPERATURE_PORT);
   call MSP430ADC12Single.bind(MSP430ADC12_INTERNAL_TEMPERATURE);
   call MSP430ADC12Multiple.bind(MSP430ADC12_INTERNAL_TEMPERATURE);
   return SUCCESS;
  }
   
  command result_t StdControl.stop() {
    return SUCCESS;
  }
 
  async command adcresult_t ADCSingle.getData()
  {
    if (call MSP430ADC12Single.getData() != MSP430ADC12_FAIL)
      return ADC_SUCCESS;
    return ADC_FAIL;
  }

  async command adcresult_t ADCSingle.getDataContinuous()
  {
    if (call MSP430ADC12Single.getDataRepeat(0) != MSP430ADC12_FAIL)
      return ADC_SUCCESS;
    return ADC_FAIL;
  }
  
  async command adcresult_t ADCSingle.reserve()
  {
    if (call MSP430ADC12Single.reserve() == SUCCESS) 
      return ADC_SUCCESS;
    return ADC_FAIL;
  }
  
  async command adcresult_t ADCSingle.reserveContinuous()
  {
    if (call MSP430ADC12Single.reserveRepeat(0) == SUCCESS) 
      return ADC_SUCCESS;
    return ADC_FAIL;
  }

  async command adcresult_t ADCSingle.unreserve()
  {
    if (call MSP430ADC12Single.unreserve() == SUCCESS) 
      return ADC_SUCCESS;
    return ADC_FAIL;
  }

  async event result_t MSP430ADC12Single.dataReady(uint16_t data)
  {
    return signal ADCSingle.dataReady(ADC_SUCCESS, data); 
  }

  default async event result_t ADCSingle.dataReady(adcresult_t result, uint16_t data)
  { 
    return FAIL;
  }


  async command adcresult_t ADCMultiple.getData(uint16_t *buf, uint16_t length)
  {
    if (call MSP430ADC12Multiple.getData(buf, length, 0) != MSP430ADC12_FAIL)
      return ADC_SUCCESS;
    return ADC_FAIL;
  }

  async command adcresult_t ADCMultiple.getDataContinuous(uint16_t *buf, uint16_t length)
  {
    if (length <= 16) {
      if (call MSP430ADC12Multiple.getDataRepeat(buf, length, 0) != MSP430ADC12_FAIL)
        return ADC_SUCCESS;
      return ADC_FAIL;
    } else {
      if (call MSP430ADC12Multiple.getData(buf, length, 0) != MSP430ADC12_FAIL){
        contMode = TRUE;
        return ADC_SUCCESS;
      } else
        return ADC_FAIL;
    }
  }

  async command adcresult_t ADCMultiple.reserve(uint16_t *buf, uint16_t length)
  {
    if (call MSP430ADC12Multiple.reserve(buf, length, 0) != MSP430ADC12_FAIL)
      return ADC_SUCCESS;
    return ADC_FAIL;
  }

  async command adcresult_t ADCMultiple.reserveContinuous(uint16_t *buf, uint16_t length)
  {
    if (call MSP430ADC12Multiple.reserveRepeat(buf, length, 0) != MSP430ADC12_FAIL)
      return ADC_SUCCESS;
    return ADC_FAIL;
  }

  async command adcresult_t ADCMultiple.unreserve()
  {
    if (call MSP430ADC12Multiple.unreserve() == SUCCESS) 
      return ADC_SUCCESS;
    return ADC_FAIL;
  }
  
  async event uint16_t* MSP430ADC12Multiple.dataReady(uint16_t *buf, uint16_t length)
  {
    uint16_t *nextbuf;
    if (!contMode)
      nextbuf = signal ADCMultiple.dataReady(SUCCESS, buf, length);
    else
      if ((nextbuf = signal ADCMultiple.dataReady(SUCCESS, buf, length)))
        call MSP430ADC12Multiple.getData(nextbuf, length, 0);
      else
        contMode = FALSE;
    return nextbuf;
  } 

  default async event uint16_t* ADCMultiple.dataReady(adcresult_t result, uint16_t *buf, uint16_t length)
  {
    return 0;
  }
  
}

