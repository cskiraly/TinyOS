// $Id: TestSchedulerM.nc,v 1.1.2.3 2005-03-21 19:34:33 scipio Exp $

/*									tab:4
 * "Copyright (c) 2000-2005 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */

/**
 * Implementation for Blink application.  Toggle the red LED when a
 * Timer fires.
 **/

includes Timer;

module TestSchedulerM {
  uses interface Leds;
  uses interface Boot;
  uses interface TaskBasic as TaskRed;
  uses interface TaskBasic as TaskGreen;
  uses interface TaskBasic as TaskBlue;
}
implementation {

  event void TaskRed.run() {
    uint16_t i, j;
    for (i= 0; i < 50; i++) {
      for (j = 0; j < 10000; j++) {}
    }
    call Leds.led0Toggle();

    if (call TaskRed.post_() == FAIL) {
      call Leds.led0Off();
    }
    else {
      call TaskRed.post_();
    }
  }

  event void TaskGreen.run() {
    uint16_t i, j;
    for (i= 0; i < 25; i++) {
      for (j = 0; j < 10000; j++) {}
    }
    call Leds.led1Toggle();

    if (call TaskGreen.post_() == FAIL) {
      call Leds.led1Off();
    }
  }

  event void TaskBlue.run() {
    uint16_t i, j;
    for (i= 0; i < 5; i++) {
      for (j = 0; j < 10000; j++) {}
    }
    call Leds.led2Toggle();

    if (call TaskBlue.post_() == FAIL) {
      call Leds.led2Off();
    }
  }

  
  
  /**
   * Event from Main that TinyOS has booted: start the timer at 1Hz.
   */
  event void Boot.booted() {
    call Leds.led2Toggle();
    call TaskRed.post_();
    call TaskGreen.post_();
    call TaskBlue.post_();
    //call Timer.setPeriodic(1000);
  }

  /** 
   * Event that Timer has fired: toggle the red LED.
   */
  
  //  event void Timer.fired() {
  //  call Leds.led0Toggle();
  // }

  
}


