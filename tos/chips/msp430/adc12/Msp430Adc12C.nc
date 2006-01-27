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
 * $Revision: 1.1.2.4 $
 * $Date: 2006-01-27 23:49:43 $
 * @author: Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */

/*
 * HAL1 of ADC12, see TEP 101.
 */
includes Msp430Adc12;
configuration Msp430Adc12C
{
  provides interface Init;
  provides interface StdControl;
  provides interface Resource[uint8_t id];
  provides interface Msp430Adc12SingleChannel as SingleChannel[uint8_t id];
}
implementation
{
  components Msp430Adc12P, HplAdc12P, MSP430TimerC, 
             Msp430RefVoltGeneratorC, HplMsp430GeneralIOC,
             new RoundRobinArbiterC(MSP430ADC12_RESOURCE) as Arbiter;

  Init = Arbiter;
  Init = Msp430Adc12P;
  Resource = Arbiter;
  SingleChannel = Msp430Adc12P.SingleChannel;
  StdControl = Msp430Adc12P.StdControlNull;
  
  Msp430Adc12P.ADCArbiterInfo -> Arbiter;
  Msp430Adc12P.HplAdc12 -> HplAdc12P;
  Msp430Adc12P.RefVoltGenerator -> Msp430RefVoltGeneratorC;
  Msp430Adc12P.Port60 -> HplMsp430GeneralIOC.Port60;
  Msp430Adc12P.Port61 -> HplMsp430GeneralIOC.Port61;
  Msp430Adc12P.Port62 -> HplMsp430GeneralIOC.Port62;
  Msp430Adc12P.Port63 -> HplMsp430GeneralIOC.Port63;
  Msp430Adc12P.Port64 -> HplMsp430GeneralIOC.Port64;
  Msp430Adc12P.Port65 -> HplMsp430GeneralIOC.Port65;
  Msp430Adc12P.Port66 -> HplMsp430GeneralIOC.Port66;
  Msp430Adc12P.Port67 -> HplMsp430GeneralIOC.Port67;

  // exclusive access to TimerA expected
  Msp430Adc12P.TimerA -> MSP430TimerC.TimerA;
  Msp430Adc12P.ControlA0 -> MSP430TimerC.ControlA0;
  Msp430Adc12P.ControlA1 -> MSP430TimerC.ControlA1;
  Msp430Adc12P.CompareA0 -> MSP430TimerC.CompareA0;
  Msp430Adc12P.CompareA1 -> MSP430TimerC.CompareA1;
}

