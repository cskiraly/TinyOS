//$Id: TimerMilliC.nc,v 1.1.2.1 2005-03-10 09:20:21 cssharp Exp $

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

// TimerMilliC is the TinyOS TimerMilli component.  OSKI will expect
// TimerMilliC to exist.  It's in the platform directory so that the platform
// can directly manage how it chooses to implement the timer.  It is fully
// expected that the standard TinyOS MultiplexTimerM component will be used for
// all platforms, and that this configuration only specifies (implicitly or
// explicitly) how precisely to use the hardware resources.

configuration TimerMilliC
{
  provides interface Init;
  provides interface Timer<TMilli> as TimerMilli[ uint8_t num ];
}
implementation
{
  components AlarmTimerMilliC
	   , new MultiplexTimerM(TMilli,uint32_t,uniqueCount("TimerMilli")) as MultiTimerMilli
	   , new SyncAlarmC(TMilli,uint32_t) as SyncAlarm
	   , new CastTimerM(TMilli) as CastTimer
	   , MathOpsM
	   ;

  /* From the bottom:
  
     1. A hardware timer is made synchronous via SyncAlarm, though the
     interface remains marked as async.
     
     2. The synchronous alarm is multiplexed into multiple timers.  This
     multiplexer thinks it's working on async, but it doesn't really matter,
     and doing it this way lets us use the same multiplexer code for both
     async and sync timers.
     
     3. Those timers are then cast to be marked as synchronous.  This is just
     a syntax change -- they're already actually synchronous because the
     synchronous alarm fed into the multiplexer.
     
     4. Finally at the top, the hardware timer and timer multiplexer need to
     be initialized.
  */

  Init = AlarmTimerMilliC;
  Init = MultiTimerMilli;

  TimerMilli = CastTimer;
  
  CastTimer.TimerFrom -> MultiTimerMilli;

  MultiTimerMilli.AlarmFrom -> SyncAlarm;
  MultiTimerMilli.Math -> MathOpsM;
  
  SyncAlarm.AlarmBaseFrom -> AlarmTimerMilliC;
}

