//$Id: TimerToAlarmM.nc,v 1.1.2.2 2005-04-01 08:30:56 cssharp Exp $

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

// Convert a Timer into an Alarm, can be used to re-Multiplex a Timer, etc.

generic module TimerToAlarmM( typedef frequency_tag, typedef size_type @integer() )
{
  provides interface AlarmBase<frequency_tag,size_type> as AlarmBase;
  uses interface TimerBase<frequency_tag,size_type> as TimerBase;
}
implementation
{
  async command size_type AlarmBase.now()
  {
    return call TimerBase.getNow();
  }

  async command size_type AlarmBase.get()
  {
    return call call TimerBase.gett0() + call TimerBase.getdt();
  }

  async command bool AlarmBase.isSet()
  {
    return call TimerBase.isRunning();
  }

  async command void AlarmBase.cancel()
  {
    call TimerBase.stop();
  }

  async command void AlarmBase.set( size_type t0, size_type dt )
  {
    call TimerBase.startOneShot( t0, dt );
  }

  async event void TimerBase.fired( size_type when, size_type numMissed )
  {
    signal AlarmBase.fired();
  }
}

