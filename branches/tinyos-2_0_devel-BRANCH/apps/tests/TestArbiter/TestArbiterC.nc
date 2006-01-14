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
 * $Revision: 1.1.2.5 $
 * $Date: 2006-01-14 09:04:20 $ 
 * ======================================================================== 
 */
 
 /**
 * TestArbiter Application  
 * This application is used to test the functionality of the arbiter 
 * components developed using the Resource and ResourceUser uinterfaces
 *
 * @author Kevin Klues (klues@tkn.tu-berlin.de)
 */

includes Timer;

module TestArbiterC {
  uses {
    interface Boot;  
    interface Leds;
    interface Resource as Resource0;
    interface Resource as Resource1;
    interface Resource as Resource2;  
    interface Timer<TMilli> as Timer0;
    interface Timer<TMilli> as Timer1;
    interface Timer<TMilli> as Timer2;
  }
}
implementation {

  #define HOLD_PERIOD 250
  
  //All resources try to gain access
  event void Boot.booted() {
    call Resource0.request();
    call Resource2.request();
    call Resource1.request();
  }
  
  //If granted the resource, turn on an LED  
  event void Resource0.granted() {
    call Timer0.startOneShot(HOLD_PERIOD);
    call Leds.led0Toggle();      
  }  
  event void Resource1.granted() {
    call Timer1.startOneShot(HOLD_PERIOD);
    call Leds.led1Toggle();     
  }  
  event void Resource2.granted() {
    call Timer2.startOneShot(HOLD_PERIOD);
    call Leds.led2Toggle();  
  }  
  
  //After the hold period release the resource
  event void Timer0.fired() {
    call Resource0.release();
    call Resource0.request();
  }
  event void Timer1.fired() {
    call Resource1.release();
    call Resource1.request();
  }
  event void Timer2.fired() {
    call Resource2.release();
    call Resource2.request();
  }
}

