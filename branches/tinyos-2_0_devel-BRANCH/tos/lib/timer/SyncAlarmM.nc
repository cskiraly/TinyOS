//$Id: SyncAlarmM.nc,v 1.1.2.4 2005-04-22 06:11:11 cssharp Exp $

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

// Translate an interrupt context alarm event to task context.
// Note that the interface is still marked async.

includes Timer;

generic module SyncAlarmM( typedef frequency_tag, typedef size_type @integer() )
{
  provides interface AlarmBase<frequency_tag,size_type> as AlarmBase;
  uses interface AlarmBase<frequency_tag,size_type> as AlarmBaseFrom;
}
implementation
{
  async command void AlarmBase.startNow( size_type dt )
  {
    return call AlarmBaseFrom.startNow(dt);
  }

  async command void AlarmBase.stop()
  {
    return call AlarmBaseFrom.stop();
  }

  task void fireAlarmBase()
  {
    signal AlarmBase.fired();
  }

  async event void AlarmBaseFrom.fired()
  {
    post fireAlarmBase();
  }

  default async event void AlarmBase.fired()
  {
  }

  async command bool AlarmBase.isRunning()
  {
    return call AlarmBaseFrom.isRunning();
  }

  async command void AlarmBase.start( size_type t0, size_type dt )
  {
    return call AlarmBaseFrom.start(t0,dt);
  }

  async command size_type AlarmBase.getNow()
  {
    return call AlarmBaseFrom.getNow();
  }

  async command size_type AlarmBase.getAlarm()
  {
    return call AlarmBaseFrom.getAlarm();
  }
}

