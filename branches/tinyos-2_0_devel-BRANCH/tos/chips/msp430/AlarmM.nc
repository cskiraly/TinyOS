//$Id: AlarmM.nc,v 1.1.2.2 2005-02-08 22:59:49 cssharp Exp $

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

generic module AlarmM( typename frequency_tag )
{
  provides interface Init;
  provides interface Alarm<frequency_tag> as Alarm;
  uses interface Counter<uint32_t,frequency_tag> as Counter;
  uses interface MSP430TimerControl;
  uses interface MSP430Compare;
}
implementation
{
  uint32_t m_alarm = 0;

  command error_t Init.init()
  {
    call MSP430TimerControl.setControlAsCompare();
  }

  async command uint32_t Alarm.get()
  {
    return call MSP430Compare.get();
  }

  async command bool Alarm.isSet()
  {
  }

  async command void Alarm.cancel()
  {
  }

  async command void Alarm.set( uint32_t t0, uint32_t dt )
  {
  }

  async event void Alarm.fired()
  {
  }
}

