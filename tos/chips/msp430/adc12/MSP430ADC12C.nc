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
 * $Date: 2005-04-19 20:59:37 $
 * @author: Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */

configuration MSP430ADC12C
{
  provides interface StdControl;
  provides interface MSP430ADC12Single[uint8_t id];
  provides interface MSP430ADC12Multiple[uint8_t id];
}

implementation
{
  components MSP430ADC12M, HPLADC12M, MSP430TimerC, RefVoltC;

  StdControl = MSP430ADC12M;
  MSP430ADC12Single = MSP430ADC12M.ADCSingle;
  MSP430ADC12Multiple = MSP430ADC12M.ADCMultiple;
    
  MSP430ADC12M.HPLADC12 -> HPLADC12M;
  MSP430ADC12M.RefVolt -> RefVoltC;

  MSP430ADC12M.TimerA -> MSP430TimerC.TimerA;
  MSP430ADC12M.ControlA0 -> MSP430TimerC.ControlA0;
  MSP430ADC12M.ControlA1 -> MSP430TimerC.ControlA1;
  MSP430ADC12M.CompareA0 -> MSP430TimerC.CompareA0;
  MSP430ADC12M.CompareA1 -> MSP430TimerC.CompareA1;
}

