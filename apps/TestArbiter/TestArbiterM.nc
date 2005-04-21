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
 *
 * - Description ----------------------------------------------------------
 * Resource Arbiter Test Application
 * - Revision -------------------------------------------------------------
 * $Revision: 1.1.2.1 $
 * $Date: 2005-04-21 19:55:30 $
 * @author Kevin Klues
 * ========================================================================
 */

module TestArbiterM {
  uses {
    interface Boot;  
    interface Leds;  
    interface ResourceUser;
    interface Resource as Resource0;
    interface Resource as Resource1;
    interface Resource as Resource2;   
  }
}
implementation {

  //Function for inserting delay so that you can see
  //  Leds as they flash
  void delay() {
    uint16_t i, j;
    for (i= 0; i < 5; i++) {
      for (j = 0; j < 30000; j++) {}
    }
  }
  
  //All resources try to gain access
  event void Boot.booted() {
    call Resource0.request();
    call Resource1.request();
    call Resource2.request();
  }
  
  //If granted the resource, turn on an LED  
  event void Resource0.granted() {
    call Leds.led0Toggle();  
  }  
  event void Resource1.granted() {
    call Leds.led1Toggle();  
  }  
  event void Resource2.granted() {
    call Leds.led2Toggle();  
  }  
  
  //If detect that someone else wants the resource,
  //  release it
  event void Resource0.requested() {
    call Resource0.release();
  }
  event void Resource1.requested() {
    call Resource1.release();
  }  
  event void Resource2.requested() {
    call Resource2.release();
  }
  
  //If see that resource is released, request it again 
  event void Resource0.released() {
    delay();
    call Resource0.request();
  }   
  event void Resource1.released() {
    delay();
    call Resource1.request();  
  }
  event void Resource2.released() {
    delay();
    call Resource2.request();  
  }   
}

