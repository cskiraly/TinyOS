//$Id: WidenAlarmM.nc,v 1.1.2.1 2005-02-08 23:00:03 cssharp Exp $

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

generic module WidenAlarmM( 
  typename to_size_type,
  typename from_size_type,
  typename frequency_tag )
{
  provides interface Alarm<to_size_type,frequency_tag> as Alarm;
  uses interface Counter<to_size_type,frequency_tag> as Counter;
  uses interface Alarm<from_size_type,frequency_tag> as AlarmFrom;
}
implementation
{
  to_size_type m_alarm = 0;

  async command uint32_t Alarm.get()
  {
    return m_alarm;
  }

  async command bool Alarm.isSet()
  {
    return call AlarmFrom.isSet();
  }

  async command void Alarm.cancel()
  {
    call AlarmFrom.cancel();
  }

  async command void Alarm.set( to_size_type t0, to_size_type dt )
  {
    to_size_type now = call Counter.get();
    to_size_type remaining = now - t0;
    m_alarm = t0+dt;
    //...
  }

  async event void AlarmFrom.fired()
  {
    //not quite, must check upper bytes, signal Alarm.fired();
  }
}

