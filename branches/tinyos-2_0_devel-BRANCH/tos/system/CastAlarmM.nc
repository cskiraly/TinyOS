//$Id: CastAlarmM.nc,v 1.1.2.3 2005-03-10 09:50:39 cssharp Exp $

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

// @author Cory Sharp <cssharp@eecs.berkeley.edu>

// Cast a 32-bit AlarmBase into a standard 32-bit Alarm.
generic module CastAlarmM( typedef frequency_tag )
{
  provides interface Alarm<frequency_tag> as Alarm;
  uses interface AlarmBase<frequency_tag,uint32_t> as AlarmFrom;
}
implementation
{
  async command uint32_t Alarm.now()
  {
    return call AlarmFrom.now();
  }

  async command uint32_t Alarm.get()
  {
    return call AlarmFrom.get();
  }

  async command bool Alarm.isSet()
  {
    return call AlarmFrom.isSet();
  }

  async command void Alarm.cancel()
  {
    return call AlarmFrom.cancel();
  }

  async command void Alarm.set( uint32_t t0, uint32_t dt )
  {
    return call AlarmFrom.set(t0,dt);
  }

  async event void AlarmFrom.fired()
  {
    signal Alarm.fired();
  }

  default async event void Alarm.fired()
  {
  }
}

