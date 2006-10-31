/*
 * "Copyright (c) 2006 Washington University in St. Louis.
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 *
 * IN NO EVENT SHALL WASHINGTON UNIVERSITY IN ST. LOUIS BE LIABLE TO ANY PARTY
 * FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING
 * OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF WASHINGTON
 * UNIVERSITY IN ST. LOUIS HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * WASHINGTON UNIVERSITY IN ST. LOUIS SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND WASHINGTON UNIVERSITY IN ST. LOUIS HAS NO
 * OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR
 * MODIFICATIONS."
 */
 
/**
 *
 * @author Kevin Klues (klueska@cs.wustl.edu)
 * @version $Revision: 1.1.2.1 $
 * @date $Date: 2006-10-31 08:44:21 $
 */
 
#include "Timer.h"

module TestSharedResourceC {
  uses {
    interface Boot;  
    interface Leds;
    interface Timer<TMilli> as Timer0;
    interface Timer<TMilli> as Timer1;
    interface Timer<TMilli> as Timer2;
    
    interface Resource as Resource0;
    interface ResourceOperations as ResourceOperations0;
    
    interface Resource as Resource1;
    interface ResourceOperations as ResourceOperations1;
    
    interface Resource as Resource2;
    interface ResourceOperations as ResourceOperations2;
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
  
  //If granted the resource, run some operation  
  event void Resource0.granted() {
  	call ResourceOperations0.operation();   
  }  
  event void Resource1.granted() {
  	call ResourceOperations1.operation();
  }  
  event void Resource2.granted() {
  	call ResourceOperations2.operation();
  }  
  
  //When the operation completes, flash the LED and hold the resource for a while
  event void ResourceOperations0.operationDone(error_t error) {
  	call Timer0.startOneShot(HOLD_PERIOD);  
    call Leds.led0Toggle();
  }
  event void ResourceOperations1.operationDone(error_t error) {
    call Timer1.startOneShot(HOLD_PERIOD);  
    call Leds.led1Toggle();
  }
  event void ResourceOperations2.operationDone(error_t error) {
    call Timer2.startOneShot(HOLD_PERIOD);  
    call Leds.led2Toggle();
  }
  
  //After the hold period release the resource and request it again
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

