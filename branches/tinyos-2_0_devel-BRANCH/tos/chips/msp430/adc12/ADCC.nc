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
 * $Revision: 1.1.2.1 $
 * $Date: 2005-06-01 03:14:27 $
 * @author: Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */

/*
 * HAL2 for ADC12 on MSP430, see TEP 101.
 * DO NOT wire to this configuration, use generic channel wrappers in
 * tinyos-2.x/tos/lib/adc instead.
 */
configuration ADCC { 
  provides {
    interface Init;
    interface StdControl;
    interface Resource[uint8_t client];
    interface AcquireData[uint8_t port];
    interface AcquireDataNow[uint8_t port];
    interface AcquireDataBuffered[uint8_t port];
  }
}
implementation {
  components ADCM, MSP430ADC12ChannelConfigM, MSP430ADC12C,
             new RoundRobinArbiter(ADC_RESOURCE) as HAL2Arbiter,
             new MSP430ADC12Client() as HAL1;
  
  Init = MSP430ADC12C;
  Init = HAL2Arbiter;
  StdControl = ADCM.StdControlNull;
  Resource = HAL2Arbiter;
  AcquireData = ADCM;
  AcquireDataNow = ADCM;
  AcquireDataBuffered = ADCM;

  ADCM.ResourceHAL1 -> HAL1.Resource;
  ADCM.SingleChannel -> HAL1.MSP430ADC12SingleChannel;
  MSP430ADC12ChannelConfigM.MSP430ADC12ChannelConfig -> ADCM.ChannelConfig;
}

