//$Id: CastTimerM.nc,v 1.1.2.1 2005-03-10 09:50:39 cssharp Exp $

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

// CastTimerM changes a TimerAsyncBase to a plain Timer.  Of course, something
// better have happened before you wire to this to have actually synchronized
// via a task the TimerAsyncBase below.  This module doesn't post the task,
// because the way it's used, it's more efficient to synchronize before a
// fan-out than after -- and this module is used after a fan-out.

generic module CastTimerM( typedef frequency_tag )
{
  provides interface Timer<frequency_tag> as Timer[ uint8_t num ];
  uses interface TimerAsyncBase<frequency_tag,uint32_t> as TimerFrom[ uint8_t num ];
}
implementation
{
  command void Timer.startPeriodicNow[ uint8_t num ]( uint32_t dt )
  {
    call TimerFrom.startPeriodicNow[num]( dt );
  }

  command void Timer.startOneShotNow[ uint8_t num ]( uint32_t dt )
  {
    call TimerFrom.startOneShotNow[num]( dt );
  }

  command void Timer.stop[ uint8_t num ]()
  {
    call TimerFrom.stop[num]();
  }

  async event void TimerFrom.fired[ uint8_t num ]( uint32_t when, uint32_t numMissed )
  {
    signal Timer.fired[num]( when, numMissed );
  }

  default event void Timer.fired[ uint8_t num ]( uint32_t when, uint32_t numMissed )
  {
  }


  command bool Timer.isRunning[ uint8_t num ]()
  {
    return call TimerFrom.isRunning[num]();
  }

  command bool Timer.isOneShot[ uint8_t num ]()
  {
    return call TimerFrom.isOneShot[num]();
  }

  command void Timer.startPeriodic[ uint8_t num ]( uint32_t t0, uint32_t dt )
  {
    call TimerFrom.startPeriodic[num]( t0, dt );
  }

  command void Timer.startOneShot[ uint8_t num ]( uint32_t t0, uint32_t dt )
  {
    call TimerFrom.startOneShot[num]( t0, dt );
  }

  command uint32_t Timer.getNow[ uint8_t num ]()
  {
    return call TimerFrom.getNow[num]();
  }

  command uint32_t Timer.gett0[ uint8_t num ]()
  {
    return call TimerFrom.gett0[num]();
  }

  command uint32_t Timer.getdt[ uint8_t num ]()
  {
    return call TimerFrom.gett0[num]();
  }
}

