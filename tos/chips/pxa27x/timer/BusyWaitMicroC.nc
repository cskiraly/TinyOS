/*
 * Copyright (c) 2005 Arched Rock Corporation 
 * All rights reserved. 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *	Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 *	Redistributions in binary form must reproduce the above copyright
 * notice, this list of conditions and the following disclaimer in the
 * documentation and/or other materials provided with the distribution.
 *  
 *   Neither the name of the Arched Rock Corporation nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE ARCHED
 * ROCK OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS
 * OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
 * TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
 * DAMAGE.
 */
/**
 * Implements the BusyWaitMicroC timer component. This component
 * instantiates a new Counter with Microsecond precision and 
 * binds it to the BusyWait interface via PXA27xBusyWaitP
 * 
 * @author Phil Buonadonna
 */
module BusyWaitMicroC
{
  provides interface BusyWait<TMicro,uint16_t> as BusyWaitMicro16;
}

implementation
{
  components new PXA27xBusyWaitP(TMicro) as PXA27xBusyWaitMicro;
  components new HalPXA27xCounterM(TMicro,4) as PXA27xCounterMicro32;
  components HplPXA27xOSTimerC;
  components PlatformP;

  BusyWaitMicro16 = PXA27xBusyWaitMicro.BusyWait;

  // Wire the initialization to the platform init routine
  PlatformP.SubInit -> PXA27xCounterMicro32.Init;
  PXA27xBusyWaitP.Counter -> PXA27xCounterMicro32.Counter;

  PXA27xCounterMicro32.OSTInit -> HplPXA27xOSTimer.Init;
  PXA27xCounterMicro32.OSTChnl -> HplPXA27xOSTimerC.OST9;
}

