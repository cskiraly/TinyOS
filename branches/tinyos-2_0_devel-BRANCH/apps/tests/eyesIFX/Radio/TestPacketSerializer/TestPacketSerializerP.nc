// $Id: TestPacketSerializerP.nc,v 1.1.2.1 2005-11-22 12:31:10 phihup Exp $

/*                                  tab:4
 * "Copyright (c) 2000-2003 The Regents of the University  of California.
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

module TestPacketSerializerP {
  uses {
	  interface Boot;
	  interface Alarm<TMilli, uint32_t> as TxTimer;
	  interface Alarm<TMilli, uint32_t> as RxTimer;
//     interface Alarm<TMilli, uint32_t> as TimerTimer;
	  interface Alarm<TMilli, uint32_t> as CCATimer;
	  interface Alarm<TMilli, uint32_t> as SelfPollingTimer;    
//     interface Alarm<TMilli, uint32_t> as SleepTimer;
	  interface Leds;
	  interface TDA5250Control;
	  interface Random;
	  interface SplitControl as RadioSplitControl;
	  interface Send;
	  interface Receive;
  }
}

implementation {
  
#define TIMER_RATE    500
#define NUM_BYTES     TOSH_DATA_LENGTH
  
  uint8_t bytes_sent;
  bool sending;
  message_t sendMsg;
  
  event void Boot.booted() {
	  uint8_t i;
	  bytes_sent = 0;
	  sending = FALSE;
	  for(i=0; i<NUM_BYTES; i++)
		  sendMsg.data[i] = 0x00;//call Random.rand16() / 2;
	  call RadioSplitControl.start();
  }
  
  event void RadioSplitControl.startDone(error_t error) {
	  call TxTimer.start(call Random.rand16() % TIMER_RATE);
//     call TimerTimer.start(call Random.rand16() % TIMER_RATE); 
	  call SelfPollingTimer.start(call Random.rand16() % TIMER_RATE); 
	  call RxTimer.start(call Random.rand16() % TIMER_RATE); 
	  call CCATimer.start(call Random.rand16() % TIMER_RATE); 
  }
  
  event void RadioSplitControl.stopDone(error_t error) {
	  call TxTimer.stop();
  }  

  /***********************************************************************
  * Commands and events
  ***********************************************************************/   

  async event void TxTimer.fired() {
	  atomic {
		  if(call TDA5250Control.TxMode() != FAIL) {
			  bytes_sent = 0;
			  sending = TRUE;
			  //call Leds.led0On();
			  //call Leds.led1On();
			  //call Leds.led2On();
			  return;
		  }
	  }
	  call TxTimer.start(call Random.rand16() % TIMER_RATE); 
  }
  
  async event void RxTimer.fired() {
	  if(sending == FALSE)
		  if(call TDA5250Control.RxMode() != FAIL) {
		  	  call Leds.led1Toggle();
			  return;
		  }
	  call RxTimer.start(call Random.rand16() % TIMER_RATE); 
  }
  
  async event void CCATimer.fired() {
	  if(sending == FALSE)  
		  if(call TDA5250Control.CCAMode() != FAIL)
			  return;
	  call CCATimer.start(call Random.rand16() % TIMER_RATE); 
  }
  
//   async event void TimerTimer.fired() {
//     if(sending == FALSE)  
//       if(call TDA5250Control.TimerMode(call Random.rand16() % TIMER_RATE/20, 
//                                        call Random.rand16() % TIMER_RATE/20) != FAIL)                        
//         return;
//     call TimerTimer.start(call Random.rand16() % TIMER_RATE);                   
//   }
  
  async event void SelfPollingTimer.fired() {
	  if(sending == FALSE)
		  if(call TDA5250Control.SelfPollingMode(call Random.rand16() % TIMER_RATE/20, 
		     call Random.rand16() % TIMER_RATE/20) != FAIL)
			  return;
	  call SelfPollingTimer.start(call Random.rand16() % TIMER_RATE); 
  }
  
//   async event void SleepTimer.fired() {
//     if(sending == FALSE)  
//       if(call TDA5250Control.SleepMode() != FAIL)
//          return;
//     call SleepTimer.start(call Random.rand16() % TIMER_RATE); 
//   }  
          
    
  async event void TDA5250Control.TxModeDone(){
	  call Send.send(&sendMsg, NUM_BYTES);
  }
  
  event void Send.sendDone(message_t* msg, error_t error) {
	  call TDA5250Control.SleepMode();
	  sending = FALSE;    
	  call TxTimer.start(call Random.rand16() % TIMER_RATE);  
	  call Leds.led0Toggle();
  }
  
  event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len) {
	  call Leds.led2Toggle();
	  return msg;
  }
  
  async event void TDA5250Control.TimerModeDone(){ 
//     call Leds.led0On();
//     call Leds.led1On();
//     call Leds.led2Off();    
  }
  async event void TDA5250Control.SelfPollingModeDone(){ 
	  call SelfPollingTimer.start(call Random.rand16() % TIMER_RATE);   
/*	  call Leds.led0On();
	  call Leds.led1Off();
	  call Leds.led2On();   */     
  }  
  async event void TDA5250Control.RxModeDone(){ 
	  call RxTimer.start(call Random.rand16() % TIMER_RATE);   
// 	  call Leds.led0Off();
// 	  call Leds.led1On();
// 	  call Leds.led2On();  
  }
  async event void TDA5250Control.SleepModeDone(){ 
//     call SleepTimer.start(call Random.rand16() % TIMER_RATE);   
// 	  call Leds.led0Off();
// 	  call Leds.led1Off();
// 	  call Leds.led2On();
  }
  async event void TDA5250Control.CCAModeDone(){ 
	  call CCATimer.start(call Random.rand16() % TIMER_RATE);   
// 	  call Leds.led0On();
// 	  call Leds.led1Off();
// 	  call Leds.led2Off();  
  }    
  
  async event void TDA5250Control.PWDDDInterrupt() {
  }  
}


