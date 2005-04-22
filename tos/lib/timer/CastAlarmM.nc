//$Id: CastAlarmM.nc,v 1.1.2.2 2005-04-22 06:11:11 cssharp Exp $

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
  async command void Alarm.startNow( uint32_t dt )
  {
    return call AlarmFrom.startNow(dt);
  }

  async command void Alarm.stop()
  {
    return call AlarmFrom.stop();
  }

  async event void AlarmFrom.fired()
  {
    signal Alarm.fired();
  }

  default async event void Alarm.fired()
  {
  }

  async command bool Alarm.isRunning()
  {
    return call AlarmFrom.isRunning();
  }

  async command void Alarm.start( uint32_t t0, uint32_t dt )
  {
    return call AlarmFrom.start(t0,dt);
  }

  async command uint32_t Alarm.getNow()
  {
    return call AlarmFrom.getNow();
  }

  async command uint32_t Alarm.getAlarm()
  {
    return call AlarmFrom.getAlarm();
  }
}

