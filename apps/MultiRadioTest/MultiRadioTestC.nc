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
 
#include "Timer.h"
 
/**
 * @author Kevin Klues
 */

module MultiRadioTestC {
  uses {
    interface Boot;
    interface Leds;
    interface SystemLowPowerListening as SLPL;

    interface SplitControl as Radio0AMControl;
    interface LowPowerListening as Radio0LPL;
    interface Receive as Radio0Receive;
    interface AMSend as Radio0AMSend;
    interface Packet as Radio0Packet;
    interface Timer<TMilli> as MilliTimer0;

    interface SplitControl as Radio1AMControl;
    interface LowPowerListening as Radio1LPL;
    interface Receive as Radio1Receive;
    interface AMSend as Radio1AMSend;
    interface Packet as Radio1Packet;
    interface Timer<TMilli> as MilliTimer1;
  }
}
implementation {

  #define LPL_INTERVAL 1000
  #define TIMER0_DELAY 2000
  #define TIMER1_DELAY 6666

  typedef struct packet_payload {
    nx_uint8_t radio_id;
    nx_uint32_t seqno;
  } packet_payload_t;

  void radio0Send();
  void radio1Send();
  message_t packet[2];

  task void radio0SendTask() {
    radio0Send();
  }

  task void radio1SendTask() {
    radio1Send();
  }

  void radio0Send() {
    packet_payload_t *r0 = call Radio0Packet.getPayload(&packet[0], sizeof(packet_payload_t));
    r0->seqno++;
    call Radio0LPL.setRemoteWakeupInterval(&packet[0], LPL_INTERVAL);
    if (call Radio0AMSend.send(AM_BROADCAST_ADDR, &packet[0], sizeof(packet_payload_t)) != SUCCESS)
      post radio0SendTask();
  }

  void radio1Send() {
    packet_payload_t *r1 = call Radio1Packet.getPayload(&packet[1], sizeof(packet_payload_t));
    r1->seqno++;
    call Radio1LPL.setRemoteWakeupInterval(&packet[1], LPL_INTERVAL);
    if (call Radio1AMSend.send(AM_BROADCAST_ADDR, &packet[1], sizeof(packet_payload_t)) != SUCCESS)
      post radio1SendTask();
  }

  event void Boot.booted() {
    call Radio0LPL.setLocalWakeupInterval(LPL_INTERVAL);
    call Radio1LPL.setLocalWakeupInterval(LPL_INTERVAL);
    call Radio0AMControl.start();
    call Radio1AMControl.start();
  }

  event void Radio0AMControl.startDone(error_t err) {
    packet_payload_t *r0 = call Radio0Packet.getPayload(&packet[0], sizeof(packet_payload_t));
    r0->radio_id = 0;
    call MilliTimer0.startOneShot(TIMER0_DELAY);
//    radio0Send();
  }

  event void Radio1AMControl.startDone(error_t err) {
    packet_payload_t *r1 = call Radio1Packet.getPayload(&packet[1], sizeof(packet_payload_t));
    r1->radio_id = 1;
    call MilliTimer1.startOneShot(TIMER1_DELAY);
//    radio1Send();
  }

  event void Radio0AMControl.stopDone(error_t err) {
    // do nothing
  }
  
  event void Radio1AMControl.stopDone(error_t err) {
    // do nothing
  }

  event void MilliTimer0.fired() {
    radio0Send();
  }

  event void MilliTimer1.fired() {
    radio1Send();
  }

  event message_t* Radio0Receive.receive(message_t* bufPtr, 
				   void* payload, uint8_t len) {
    call Leds.led2Toggle();
    return bufPtr;
  }

  event message_t* Radio1Receive.receive(message_t* bufPtr, 
				   void* payload, uint8_t len) {
    call Leds.led2Toggle();
    return bufPtr;
  }

  event void Radio0AMSend.sendDone(message_t* bufPtr, error_t error) {
    if(error == SUCCESS)
      call Leds.led0Toggle();
//    radio0Send();
    call MilliTimer0.startOneShot(TIMER0_DELAY);
  }
  
  event void Radio1AMSend.sendDone(message_t* bufPtr, error_t error) {
    if(error == SUCCESS)
      call Leds.led1Toggle();
//    radio1Send();
    call MilliTimer1.startOneShot(TIMER1_DELAY);
  }

}

