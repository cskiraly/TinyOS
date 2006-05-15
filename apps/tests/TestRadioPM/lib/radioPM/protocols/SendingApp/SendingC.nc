/*
 * "Copyright (c) 2005 Washington University in St. Louis.
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
 * @date $Date: 2006-05-15 19:36:09 $
 */

#include "DutyCycling.h"

generic module SendingC(DutyCycleModes onTime, DutyCycleModes offTime) {
  uses {
    interface Boot;
    interface Leds;
    interface RadioDutyCycling;
    interface AMSend as AMSender;
    interface Packet;
    interface Timer<TMilli> as SendTimer;
    interface Random;
  }
}
implementation {

  message_t packet;

  event void Boot.booted() {
    uint8_t* nodeId;
    call RadioDutyCycling.setModes(onTime, offTime);
    nodeId = (uint8_t*)call Packet.getPayload(&packet, NULL);
    *nodeId = TOS_NODE_ID;
  }

  event void AMSender.sendDone(message_t* bufPtr, error_t error) {
    if (error != SUCCESS) {
      call Leds.led0On();
      call Leds.led1On();
      call Leds.led2On();
    }
  }

  event void RadioDutyCycling.beginOnTime() {
	  uint32_t randnum;
	  randnum = call Random.rand16();
	  randnum = randnum*(onTime*DUTY_CYCLE_STEP-50)/0xFFFF;
	  //randnum = onTime*DUTY_CYCLE_STEP - 100;
	  //don't send the data during the first 50ms, wait for the receiver to get ready
	  //call Leds.led1Toggle();
	  call SendTimer.startOneShot(10+randnum);
  }

  event void SendTimer.fired(){
    if(call AMSender.send(AM_BROADCAST_ADDR, &packet, 50*sizeof(uint8_t)) == SUCCESS)
	  call Leds.led0Toggle();
  }
  event void RadioDutyCycling.beginOffTime() {
  }
}
