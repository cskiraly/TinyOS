//$Id: MSP430AlarmM.nc,v 1.1.2.1 2005-02-11 01:56:11 cssharp Exp $

/* "Copyright (c) 2000-2003 The Regents of the University of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement
 * is hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY
 * OF CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 */

//@author Cory Sharp <cssharp@eecs.berkeley.edu>

// The TinyOS Timer interfaces are discussed in TEP 102.

generic module MSP430AlarmM(typedef frequency_tag)
{
  provides interface Init;
  provides interface AlarmBase<uint16_t,frequency_tag> as Alarm;
  uses interface MSP430Timer;
  uses interface MSP430TimerControl;
  uses interface MSP430Compare;
}
implementation
{
  command error_t Init.init()
  {
    call MSP430TimerControl.disableEvents();
    call MSP430TimerControl.setControlAsCompare();
    return SUCCESS;
  }
  
  async command uint16_t Alarm.now()
  {
    return call MSP430Timer.get();
  }

  async command uint16_t Alarm.get()
  {
    return call MSP430Compare.getEvent();
  }

  async command bool Alarm.isSet()
  {
    return call MSP430TimerControl.areEventsEnabled();
  }

  async command void Alarm.cancel()
  {
    call MSP430TimerControl.disableEvents();
  }

  async command void Alarm.set( uint16_t t0, uint16_t dt )
  {
    uint16_t now = call MSP430Timer.get();
    uint16_t elapsed = now - t0;
    if( elapsed >= dt )
    {
      call MSP430Compare.setEventFromNow(2);
    }
    else
    {
      uint16_t remaining = dt - elapsed;
      if( remaining <= 2 )
	call MSP430Compare.setEventFromNow(2);
      else
	call MSP430Compare.setEvent( now+remaining );
    }
    call MSP430TimerControl.enableEvents();
  }

  async event void MSP430Compare.fired()
  {
    call MSP430TimerControl.disableEvents();
    signal Alarm.fired();
  }

  async event void MSP430Timer.overflow()
  {
  }
}

