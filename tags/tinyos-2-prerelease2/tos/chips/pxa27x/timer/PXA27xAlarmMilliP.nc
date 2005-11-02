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
 * Provides multiple alarms via a parameterized interface from a single
 * alarm built on an OS Timer channel.
 *
 * @author Philip Buonadonna
 */

configuration PXA27xAlarmMilliP
{
  provides {
    interface Init;
    interface Alarm<TMilli,uint32_t> as Alarm32khz32[uint8_t num];
  }
}

implementation
{
  components new VirtualizeAlarmC(TMilli,uint32_t,16) as VirtAlarms32khz32;
  components new HalPXA27xAlarmM(TMilli,2) as PhysAlarm32khz32;
  components HplPXA27xOSTimerC;

  Init = VirtAlarms32khz32;
  Init = HplPXA27xOSTimerP;
  Alarm32khz32 = VirtAlarms32khz32.Alarm;

  VirtAlarms32khz32.AlarmFrom -> PhysAlarm32khz32.Alarm32;
  
  PhysAlarm32khz32.OSTInit -> HplPXA27xOSTimerC.Init;
  PhysAlarm32khz.OSTChnl -> HplPXA27xOSTimerC.OST5;

}
