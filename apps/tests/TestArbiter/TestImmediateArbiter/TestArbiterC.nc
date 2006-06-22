/*
 * Copyright (c) 2004, Technische Universitat Berlin
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright notice,
 *   this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the distribution.
 * - Neither the name of the Technische Universitat Berlin nor the names
 *   of its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA,
 * OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */
 
/**
 * Please refer to TEP 108 for more information about the components
 * this application is used to test
 *
 * This application is used to test the functionality of the
 * FcfsArbiter component developed using the Resource
 * interface.  Three Resource users are created and all three request
 * control of the resource before any one of them is granted it.
 * Once the first user is granted control of the resource, a timer
 * is set to allow this user to have control of it for a specific
 * amount of time.  Once this timer expires, the resource is released
 * and then immediately requested again.  Upon releasing the resource
 * control will be granted to the next user that has
 * requested it in FCFS order.  Initial requests are made
 * by the three resource users in the following order<br>
 * <li> Resource 0
 * <li> Resource 2
 * <li> Resource 1
 * <br>
 * It is expected then that using a round robin policy, control of the
 * resource will be granted in the order of 0,2,1 and the Leds
 * corresponding to each resource will flash whenever this occurs.<br>
 * <li> Led 0 -> Resource 0
 * <li> Led 1 -> Resource 1
 * <li> Led 2 -> Resource 2
 * <br>
 *
 * @author Kevin Klues <klues@tkn.tu-berlin.de>
 * @version  $Revision: 1.1.2.1 $
 * @date $Date: 2006-06-22 12:51:44 $
 */

#include "Timer.h"

module TestArbiterC {
  uses {
    interface Boot;  
    interface Leds;
    interface ImmediateResource as Resource0;
    interface ImmediateResource as Resource1;
    interface ImmediateResource as Resource2;
    interface Timer<TMilli> as Timer0;
    interface Timer<TMilli> as Timer1;
    interface Timer<TMilli> as Timer2;
  }
}
implementation {

  #define HOLD_PERIOD 250
  
  //All resources try to gain access
  event void Boot.booted() {
    if(call Resource0.request() == SUCCESS) {
      call Timer0.startOneShot(HOLD_PERIOD);
      call Leds.led0Toggle();
    }
    if(call Resource1.request() == SUCCESS) {
      call Timer1.startOneShot(HOLD_PERIOD);
      call Leds.led1Toggle();
    }
    if(call Resource2.request() == SUCCESS) {
      call Timer2.startOneShot(HOLD_PERIOD);
      call Leds.led2Toggle();
    }
  }
  
  //After the hold period release the resource
  event void Timer0.fired() {
    call Resource0.release();
    if(call Resource1.request() == SUCCESS) {
      call Timer1.startOneShot(HOLD_PERIOD);
      call Leds.led1Toggle();
    }
    if(call Resource2.request() == SUCCESS) {
      call Timer2.startOneShot(HOLD_PERIOD);
      call Leds.led2Toggle();
    }
    if(call Resource0.request() == SUCCESS) {
      call Timer0.startOneShot(HOLD_PERIOD);
      call Leds.led0Toggle();
    }
  }
  event void Timer1.fired() {
    call Resource1.release();
    if(call Resource2.request() == SUCCESS) {
      call Timer2.startOneShot(HOLD_PERIOD);
      call Leds.led2Toggle();
    }
    if(call Resource0.request() == SUCCESS) {
      call Timer0.startOneShot(HOLD_PERIOD);
      call Leds.led0Toggle();
    }
    if(call Resource1.request() == SUCCESS) {
      call Timer1.startOneShot(HOLD_PERIOD);
      call Leds.led1Toggle();
    }
  }
  event void Timer2.fired() {
    call Resource2.release();
    if(call Resource0.request() == SUCCESS) {
      call Timer0.startOneShot(HOLD_PERIOD);
      call Leds.led0Toggle();
    }
    if(call Resource1.request() == SUCCESS) {
      call Timer1.startOneShot(HOLD_PERIOD);
      call Leds.led1Toggle();
    }
    if(call Resource2.request() == SUCCESS) {
      call Timer2.startOneShot(HOLD_PERIOD);
      call Leds.led2Toggle();
    }
  }
}

