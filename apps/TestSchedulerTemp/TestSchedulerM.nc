// $Id: TestSchedulerM.nc,v 1.1.2.2 2005-03-19 20:59:15 scipio Exp $

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
}
implementation {

  task void TaskRed();
  task void TaskGreen();
  task void TaskBlue();
  
  task void TaskRed() {
    uint16_t i, j;
    call Leds.led1On();
    for (i= 0; i < 250; i++) {
      for (j = 0; j < 30000; j++) {}
    }

    if (post TaskRed() != 0) {
      call Leds.led1Off();
      post TaskGreen();
      post TaskBlue();
    }
  }

  task void TaskGreen() {
    uint16_t i, j;
    call Leds.led2On();
    for (i= 0; i < 125; i++) {
      for (j = 0; j < 30000; j++) {}
    }

    if (post TaskGreen() != 0) {
      call Leds.led2Off();
    }
  }

  task void TaskBlue() {
    uint16_t i, j;
    call Leds.led3On();
    for (i= 0; i < 25; i++) {
      for (j = 0; j < 30000; j++) {}
    }

    if (post TaskBlue() != 0) {
      call Leds.led3Off();
    }
  }

  
  
  /**
   * Event from Main that TinyOS has booted: start the timer at 1Hz.
   */
  event void Boot.booted() {
    call Leds.led3Toggle();
    post TaskRed();
    post TaskGreen();
    post TaskBlue();
    //call Timer.setPeriodic(1000);
  }

  /** 
   * Event that Timer has fired: toggle the red LED.
   */
  
  //  event void Timer.fired() {
  //  call Leds.led1Toggle();
  // }

  
}


