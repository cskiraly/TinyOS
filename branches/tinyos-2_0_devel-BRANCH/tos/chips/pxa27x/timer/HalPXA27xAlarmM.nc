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
 * @author Phil Buonadonna
 *
 */

// @author Phil Buonadonna

includes Timer;

generic module HalPXA27xAlarmM(typedef frequency_tag, uint8_t resolution) 
{
  provides {
    interface Init;
    interface Alarm<frequency_tag,uint32_t> as Alarm;
  }
  uses {
    interface Init as OSTInit;
    interface HplPXA27xOSTimer as OSTChnl;
  }
}

implementation
{
  bool gfRunning;

  command error_t Init.init() {

    call OSTInit.init(); 
    //OIER &= ~(1 << channel);
    //OSTIrq.allocate();
    //OSTIrq.enable();

    // Continue on match, Non-periodic, w/ given resolution
    atomic {
      gfRunning = FALSE;
      //OMCR(channel) = (OMCR_C | OMCR_P | OMCR_CRES(resolution));
      call OSTChnl.setOMCR(OMCR_C | OMCR_P | OMCR_CRES(resolution));
      //OSCR(channel) = 0;  // Start the counter
      call OSTChnl.setOSCR(0);
    }
    return SUCCESS;

  }

  async command void Alarm.start( uint32_t dt ) {
    uint32_t tf;

    tf = (call OSTChnl.getOSCR()) + dt;
    atomic {
      call OSTChnl.disableInterrupt();
      call OSTChnl.setOSMR(tf);
      call OSTChnl.enableInterrupt();
      gfRunning = TRUE;
    }
    return;
  }

  async command void Alarm.stop() {
    atomic {
      // OIER &= ~(1 << channel);
      call OSTChnl.disableInterrupt();
      gfRunning = FALSE;
    }
    return;
  }

  async command bool Alarm.isRunning() {
    bool flag;

    atomic flag = gfRunning;
    return flag;
  }
  
  async command void Alarm.startAt( uint32_t t0, uint32_t dt ) {
    uint32_t tf;
    tf = t0 + dt;
    atomic {
      call OSTChnl.disableInterrupt();
      call OSTChnl.setOSMR(tf);
      call OSTChnl.enableInterrupt();
      gfRunning = TRUE;
    }

    return;
  } 

  async command uint32_t Alarm.getNow() {
    return call OSTChnl.getOSCR(); //OSCR(channel);
  }

  async command uint32_t Alarm.getAlarm() {
    return call OSTChnl.getOSMR(); //OSMR(channel);
  }

  async event void OSTChnl.fired() {
    if (call OSTChnl.getStatus()) {
      atomic {
	call OSTChnl.disableInterrupt();
	gfRunning = FALSE;
      }
      signal Alarm.fired();
    }
    return;
  }

  default async event void Alarm.fired() {
    return;
  }


}

