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
 * MyComponentP module
 *
 * @author Kevin Klues (klueska@cs.wustl.edu)
 */
 
module MyComponentP {
  provides {
    interface SplitControl;
    interface StdControl;
  }
  uses {
    interface Leds;
    interface Timer<TMilli> as StartTimer;
    interface Timer<TMilli> as StopTimer;
  }
}
implementation {

  #define START_DELAY 10
  #define STOP_DELAY 10

  command error_t SplitControl.start() {
    call StartTimer.startOneShot(START_DELAY);
    return SUCCESS;
  }

  event void StartTimer.fired() {
    call Leds.led0On();
    signal SplitControl.startDone(SUCCESS);
  }

  command error_t SplitControl.stop() {
    call StopTimer.startOneShot(STOP_DELAY);
    return SUCCESS;
  }

  event void StopTimer.fired() {
    call Leds.led0Off();
    signal SplitControl.stopDone(SUCCESS);
  }

  command error_t StdControl.start() {
    call Leds.led0On();
    return SUCCESS;
  }

  command error_t StdControl.stop() {
    call Leds.led0Off();
    return SUCCESS;
  }

  default event void SplitControl.startDone(error_t error) {}
  default event void SplitControl.stopDone(error_t error) {}
}

