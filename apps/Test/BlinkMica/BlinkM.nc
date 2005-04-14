// $Id: BlinkM.nc,v 1.1.2.1 2005-04-14 08:20:44 mturon Exp $

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

/**
 * This version of Blink is designed to test ATmega128 AVR timers.
 */
generic module BlinkM(typedef timer_size @integer())
{
  uses interface HPLTimerCtrl8 as TimerControl;
  uses interface HPLTimer<timer_size> as Timer;
  uses interface HPLCompare<timer_size> as Compare;
  uses interface Boot;
  uses interface Leds;
}
implementation
{
  norace int cnt;

  void timer_init() {

      atomic {
	  ATm128TimerControl_t clk_init;
	  clk_init.bits.cs = 2;    // prescale CLK/4
	  call TimerControl.setControl(clk_init);  

	  call Compare.set(0x80);  // trigger compare in middle of range 

	  call Timer.start();
	  call Compare.start();

	  call Timer.set(6);      // overflow after 256-6 = 250 cycles
      }
  }
  
  void poll_timer() {
      uint16_t i,j;
      while(1) {
	  for (i= 0; i < 15; i++) {
	      for (j = 0; j < 30000; j++) {
		  asm volatile  ("nop" ::);
	      }
	      //call Leds.led1Toggle();
	  }
	  call Leds.led1Toggle();
      }
  }

  event void Boot.booted() {

      cnt = 10000;

      timer_init();

      call Leds.led1On();

      poll_timer();

      call Leds.led0On();
  }
 
  async event void Compare.fired() {
      call Compare.reset();
      if (cnt > 500) {
	  call Leds.led2Toggle();
      } 
  }

  async event void Timer.overflow() {
      call Timer.reset();
      call Timer.set(6);      // keep timer overflow at ~125 usec.
      if (cnt++ > 1000) {
	  call Leds.led0Toggle();
	  cnt = 0;
      }
  }
}

