/// $Id: Atm128AlarmP.nc,v 1.1.2.3 2005-09-22 00:46:26 scipio Exp $

/**
 * Copyright (c) 2004-2005 Crossbow Technology, Inc.  All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL CROSSBOW TECHNOLOGY OR ANY OF ITS LICENSORS BE LIABLE TO 
 * ANY PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL 
 * DAMAGES ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN
 * IF CROSSBOW OR ITS LICENSOR HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH 
 * DAMAGE. 
 *
 * CROSSBOW TECHNOLOGY AND ITS LICENSORS SPECIFICALLY DISCLAIM ALL WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY 
 * AND FITNESS FOR A PARTICULAR PURPOSE. THE SOFTWARE PROVIDED HEREUNDER IS 
 * ON AN "AS IS" BASIS, AND NEITHER CROSSBOW NOR ANY LICENSOR HAS ANY 
 * OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR 
 * MODIFICATIONS.
 */

/// @author Martin Turon <mturon@xbow.com>

generic module Atm128AlarmP(typedef frequency_tag, 
			     typedef timer_size @integer(),
			     uint8_t prescalar)
{
  provides interface Init;
  provides interface Alarm<frequency_tag, timer_size> as Alarm;

  uses interface HplTimer<timer_size>;
  uses interface HplCompare<timer_size>;
}
implementation
{
  command error_t Init.init() {
    atomic {
      call HplCompare.stop();
      call HplTimer.set(0);
      call HplTimer.start();
      call HplTimer.setScale(prescalar);
    }
    return SUCCESS;
  }
  
  async command timer_size Alarm.getNow() {
    return call HplTimer.get();
  }

  async command timer_size Alarm.getAlarm() {
    return call HplCompare.get();
  }

  async command bool Alarm.isRunning() {
    return call HplCompare.isOn();
  }

  async command void Alarm.stop() {
    call HplCompare.stop();
  }

  async command void Alarm.startNow( timer_size dt ) 
  {
    call Alarm.start( call HplTimer.get(), dt);
  }

  async command void Alarm.start( timer_size t0, timer_size dt ) {
    timer_size now;
    timer_size expires, guardedExpires;

    /* Setting the compare register while the timer is = 0 seems
       to be a bad idea... (lost overflow interrupts) */
    while (!(now = call HplTimer.get()))
      ;

    /* We require dt >= 2 to avoid horrible complexity in the guarded
       expiry case and because the hardware doesn't support interrupts in the
       next timer-clock cycle */
    if (dt < 2)
      dt = 2;

    expires = t0 + dt;
    /* Re the comment above: it's a bad idea to wake up at time 0, as we'll
       just spin when setting the next deadline. Try and reduce the
       likelihood by delaying the interrupt...
    */
    if (expires == 0 || expires == (timer_size)-1)
      expires = 1;
    guardedExpires = expires - 2;

    /* t0 is assumed to be in the past. If it's numerically greater than
       now, that just represents a time one wrap-around ago. This requires
       handling the t0 <= now and t0 > now cases separately. 

       Note also that casting compared quantities to timer_size produces
       predictable comparisons (the C integer promotion rules would make it
       hard to write correct code for the possible timer_size size's) */
    if (t0 <= now)
      {
	/* if it's in the past or the near future, fire now (i.e., test
	   guardedExpires <= now in wrap-around arithmetic). */
	if (guardedExpires >= t0 && // if it wraps, it's > now
	    guardedExpires <= now) 
	  call HplCompare.set(call HplTimer.get() + 2);
	else
	  call HplCompare.set(expires);
      }
    else
      {
	/* again, guardedExpires <= now in wrap-around arithmetic */
	if (guardedExpires >= t0 || // didn't wrap so < now
	    guardedExpires <= now)
	  call HplCompare.set(call HplTimer.get() + 2);
	else
	  call HplCompare.set(expires);
      }
    call HplCompare.start();
  }

  async event void HplCompare.fired() {
    call HplCompare.stop();
    signal Alarm.fired();
  }

  async event void HplTimer.overflow() {
  }
}
