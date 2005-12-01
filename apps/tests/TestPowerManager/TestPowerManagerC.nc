/* Copyright (C) 2005, Washington University in Saint Louis 
 * 
 * Washington University states that this is free software; 
 * you can redistribute it and/or modify it under the terms of 
 * the current version of the GNU Lesser General Public License 
 * as published by the Free Software Foundation.
 * 
 * This software is distributed in the hope that it will be useful, but 
 * THERE ARE NO WARRANTIES, WHETHER ORAL OR WRITTEN, EXPRESS OR 
 * IMPLIED, INCLUDING BUT NOT LIMITED TO, IMPLIED WARRANTIES OF 
 * MERCHANTABILITY OR FITNESS FOR A PARTICULAR USE.
 *
 * YOU UNDERSTAND THAT THIS SOFTWARE IS PROVIDED "AS IS" FOR WHICH NO 
 * WARRANTIES AS TO CAPABILITIES OR ACCURACY ARE MADE. THERE ARE NO 
 * WARRANTIES AND NO REPRESENTATION THAT THIS SOFTWARE IS FREE OF 
 * INFRINGEMENT OF THIRD PARTY PATENT, COPYRIGHT, OR OTHER 
 * PROPRIETARY RIGHTS.  THERE ARE NO WARRANTIES THAT SOFTWARE IS 
 * FREE FROM "BUGS", "VIRUSES", "TROJAN HORSES", "TRAP DOORS", "WORMS", 
 * OR OTHER HARMFUL CODE.  
 *
 * YOU ASSUME THE ENTIRE RISK AS TO THE PERFORMANCE OF SOFTWARE AND/OR 
 * ASSOCIATED MATERIALS, AND TO THE PERFORMANCE AND VALIDITY OF 
 * INFORMATION GENERATED USING SOFTWARE. By using this code you agree to 
 * indemnify, defend, and hold harmless WU, its employees, officers and 
 * agents from any and all claims, costs, or liabilities, including 
 * attorneys fees and court costs at both the trial and appellate levels 
 * for any loss, damage, or injury caused by your actions or actions of 
 * your officers, servants, agents or third parties acting on behalf or 
 * under authorization from you, as a result of using this code. 
 *
 * See the GNU Lesser General Public License for more details, which can 
 * be found here: http://www.gnu.org/copyleft/lesser.html
 *
 */
 
 /**
 * TestPowerManager Application  
 * This application is used to test the functionality of the non mcu power  
 * management component
 *
 * @author Kevin Klues (klueska@cs.wustl.edu)
 */
 
includes Timer;

module TestPowerManagerC {
  uses {
    interface Boot;  
    interface Leds;
    interface Resource as Resource0;
    interface Resource as Resource1;
    interface Timer<TMilli> as TimerMilli;
  }
}
implementation {

  #define HOLD_PERIOD 500
  #define WAIT_PERIOD 1000
  uint8_t whoHasIt;
  uint8_t waiting;
  
  //All resources try to gain access
  event void Boot.booted() {
    call Resource0.request();
    waiting = FALSE;
  }
  
  //If granted the resource, turn on an LED  
  event void Resource0.granted() {
    whoHasIt = 0;
    call Leds.led1On();
    call TimerMilli.startOneShot(HOLD_PERIOD);
  }  

  event void Resource1.granted() {
    whoHasIt = 1;
    call Leds.led2On();
    call TimerMilli.startOneShot(HOLD_PERIOD);
  }

  event void TimerMilli.fired() {
    if(waiting == TRUE) {
      waiting = FALSE;
      if(whoHasIt == 0)
        call Resource1.request();
      if(whoHasIt == 1)
        call Resource0.request();
    }
    else {
      if(whoHasIt == 0) {
        call Leds.led1Off();
        call Resource0.release();
      }
      if(whoHasIt == 1) {
        call Leds.led2Off();
        call Resource1.release();
      }
      waiting = TRUE;
      call TimerMilli.startOneShot(WAIT_PERIOD);
    }
  }
}

