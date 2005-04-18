/// $Id: HALAlarmM.nc,v 1.1.2.2 2005-04-18 01:35:59 mturon Exp $

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

generic module HALAlarmM(typedef frequency_tag, 
			 typedef timer_size @integer())
{
    provides interface Init;
    provides interface AlarmBase<frequency_tag,timer_size> as Alarm;

    uses interface HPLTimer<timer_size>;
    uses interface HPLCompare<timer_size>;
}
implementation
{
  command error_t Init.init() {
      atomic {
	  call HPLCompare.stop();

	  sbi (ASSR,  AS0);  // set Timer/Counter0 to use 32,768khz crystal
	  call HPLTimer.setScale(AVR_CLOCK_OFF);
	  call HPLTimer.set(0);
	  call HPLTimer.start();
	  call HPLTimer.setScale(AVR_CLOCK_ON);

	  cbi(MCUCR, SE);    // disable sleep instruction -- temp workaround!
      }
      return SUCCESS;
  }
  
  async command timer_size Alarm.now() {
      return call HPLTimer.get();
  }

  async command timer_size Alarm.get() {
      return call HPLCompare.get();
  }

  async command bool Alarm.isSet() {
      return call HPLCompare.isOn();
  }

  async command void Alarm.cancel() {
      call HPLCompare.stop();
  }

  async command void Alarm.set( timer_size t0, timer_size dt ) 
  {
      timer_size now = call HPLTimer.get();
      timer_size elapsed = now - t0;
      if( elapsed >= dt )
      {
	  atomic { call HPLCompare.set( call HPLTimer.get() + 2 ); }
      }
      else
      {
	  timer_size remaining = dt - elapsed;
	  if( remaining <= 2 )
	      atomic { call HPLCompare.set( call HPLTimer.get() + 2 ); }
	  else
	      call HPLCompare.set( now + remaining );
      }
      call HPLCompare.start();
  }
  
  async event void HPLCompare.fired() {
      call HPLCompare.stop();
      signal Alarm.fired();
  }

  async event void HPLTimer.overflow() {
  }
}

