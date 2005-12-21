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
 * - Revision -------------------------------------------------------------
 * $Revision: 1.1.2.3 $
 * $Date: 2005-12-21 19:02:40 $ 
 * ======================================================================== 
 */
 
 /**
 * TestArbiter Application  
 * This application is used to test the functionality of the arbiter 
 * components developed using the Resource and ResourceUser uinterfaces
 *
 * @author Kevin Klues (klues@tkn.tu-berlin.de)
 * @author Philipp Huppertz (extended test FcfsPriorityArbiter)
 */

includes Timer;

module TestPriorityArbiterC {
  uses {
    interface Boot;  
    interface Leds;
    interface Resource as Resource1;
    interface Resource as Resource2;  
    interface ResourceController as Resource3;
    interface ResourceController as Resource4;
    interface ArbiterInfo;
    interface Timer<TMilli> as TimerResource1;
    interface Timer<TMilli> as TimerResource2;
    interface Timer<TMilli> as TimerResource4;
  }
}
implementation {

#define RESOURCE4_FULL_PERIOD     8000
#define RESOURCE4_SAFE_PERIOD     1000
#define RESOURCE4_SLEEP_PERIOD    10000

#define RESOURCE2_ACTIVE_PERIOD   1000
#define RESOURCE2_WAIT_PERIOD     6000

#define RESOURCE1_ACTIVE_PERIOD   2000
#define RESOURCE1_WAIT_PERIOD     6000



  // internal states of Resource4 (High Prio Resource)
  uint8_t sleepCnt = 0;
  bool resReq = FALSE;
  
  // internal state Resources (active / not active)
  bool res1Active = FALSE;
  bool res2Active = FALSE;
  
  
  task void startResource4SafePeriod() {
    call TimerResource4.stop();
    call TimerResource4.startOneShot(RESOURCE4_SAFE_PERIOD);
  }
  
  event void TimerResource1.fired() {
    if (res1Active) {
      call Resource1.release();
      call TimerResource1.startOneShot(RESOURCE1_WAIT_PERIOD);
      call Leds.led0Off();    
      res1Active = FALSE;
    } else {
      call Leds.led0Toggle();
      uwait(100);
      call Leds.led0Toggle();
      call Resource1.request();
    }
  }
  
  event void TimerResource2.fired() {
    if (res2Active) {
      call Resource2.release();
      call TimerResource2.startOneShot(RESOURCE2_WAIT_PERIOD);
      call Leds.led1Off(); 
      res2Active = FALSE;
    } else {
      call Leds.led1Toggle();
      uwait(100);
      call Leds.led1Toggle();
      call Resource2.request();
    }
  }
  
  event void TimerResource4.fired() {
    call Leds.led0Toggle();
    call Leds.led1Toggle();
    call Leds.led2Toggle();
    uwait(100);
    call Leds.led0Toggle();
    call Leds.led1Toggle();
    call Leds.led2Toggle();
    call Resource4.release();
    // and request again 'cause we know that one client will be served in between...
    call Resource4.request();
    atomic {resReq = FALSE;}
  }
 
 
  //All resources try to gain access
  event void Boot.booted() {
    call Resource1.request();
    call Resource2.request();
    call Resource4.request(); 
  }
  
  //If granted the resource, turn on an LED  
  event void Resource1.granted() {
    call Leds.led0On();    
    call Leds.led1Off(); 
    call Leds.led2Off();   
    call TimerResource1.startOneShot(RESOURCE1_ACTIVE_PERIOD);
    res1Active = TRUE; 
  }  
  
  event void Resource2.granted() {
    call Leds.led0Off();
    call Leds.led1On(); 
    call Leds.led2Off(); 
    call TimerResource2.startOneShot(RESOURCE2_ACTIVE_PERIOD);
    res2Active = TRUE;    
  }  
  event void Resource3.granted() {
    call Leds.led0Off(); 
    call Leds.led1Off(); 
    call Leds.led2On();  
 
  }  
  event void Resource4.granted() {
    if (sleepCnt > 4) {
      // immediatly release resource and sleep
      call Resource4.release();
      call TimerResource4.startOneShot(RESOURCE4_SLEEP_PERIOD);  
      sleepCnt = 0;
    } else {
      call Leds.led0On();  
      call Leds.led1On(); 
      call Leds.led2On(); 
      if (resReq) {
       call TimerResource4.startOneShot(RESOURCE4_SAFE_PERIOD);  
      } else {
       call TimerResource4.startOneShot(RESOURCE4_FULL_PERIOD);  
      }
    }
    ++sleepCnt;
  }  
  
  //If detect that someone else wants the resource,
  //  release it 
  async event void Resource3.requested() {
    call Resource3.release();
  }
  
  //If detect that someone else wants the resource,
  //  release it if its safe 
  async event void Resource4.requested() {
    if (!resReq) {
      if (call ArbiterInfo.userId() == call Resource4.getId() ) {
        post startResource4SafePeriod();
      } else {}
      atomic {resReq = TRUE;}
    }
  }
  
  // do something
  async event void Resource3.idle() {
    call Resource3.request(); 
  }
  
  // do nothing
  async event void Resource4.idle() {
  }
}

