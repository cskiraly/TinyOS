// $Id: ChainedSSSSenderC.nc,v 1.1.2.1 2006-05-15 19:36:07 klueska Exp $

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

/**
 * Application to test that the TinyOS java toolchain can communicate
 * with motes over the serial port. The application sends packets to
 * the serial port at 1Hz: the packet contains an incrementing
 * counter. When the application receives a counter packet, it
 * displays the bottom three bits on its LEDs. This application is
 * very similar to RadioCountToLeds, except that it operates over the
 * serial port. There is Java application for testing the mote
 * application: run TestSerial to print out the received packets and
 * send packets to the mote.
 *
 *  @author Gilman Tolle
 *  @author Philip Levis
 *  
 *  @date   Aug 12 2005
 *
 **/

includes Timer;
includes SenderAddr;

module ChainedSSSSenderC {
  uses {
    interface SplitControl as AMRadioControl;
    interface SplitControl as RadioDutyCyclingControl;
    interface Leds;
    interface Boot;
    interface Receive as RadioReceive;
    interface AMSend as AMRadioSend;
    interface Timer<TMilli> as Timer;
    interface Packet as RadioPacket; 
    interface SplitControl as AMSerialControl;
    interface AMSend as AMSerialSend;
    interface Packet as SerialPacket;
    interface AMPacket;
    interface RadioDutyCycling;
  }
}
implementation {

  #define SEND_RADIO_PERIOD 2000
  #define SEND_TO_ADDR (call AMPacket.address() + 1 )

  message_t radioPacket;
  message_t serialPacket;
  uint32_t sendTime;

  event void Boot.booted() {
    ChainedMsg* m = (ChainedMsg*)call RadioPacket.getPayload(&radioPacket, NULL);
    m->goingForward = TRUE;
    m->seqNo = 0;
    call RadioDutyCycling.setModes(CURRENT_DUTY_CYCLE_ON, CURRENT_DUTY_CYCLE_OFF);
    call AMSerialControl.start();
  }

  event void Timer.fired() {
    ChainedMsg* m = (ChainedMsg*)call RadioPacket.getPayload(&radioPacket, NULL);
    if(++(m->seqNo) >= MAX_NUM_MESSAGES)
      call AMSerialSend.send(AM_BROADCAST_ADDR, &serialPacket, sizeof(DelayChainedMsgs));
    else call AMRadioSend.send(SEND_TO_ADDR, &radioPacket, TOSH_DATA_LENGTH);
  }

  event void AMSerialSend.sendDone(message_t* bufPtr, error_t error) {
    call Leds.led1Toggle();
    call RadioDutyCyclingControl.stop();
  }

  event void AMRadioSend.sendDone(message_t* bufPtr, error_t error) {
    sendTime = call Timer.getNow();
    call Leds.led2Toggle();
    call Timer.startOneShot(SEND_RADIO_PERIOD);
  }

  event message_t* RadioReceive.receive(message_t* bufPtr, 
           void* payload, uint8_t len) {
    ChainedMsg* rm = (ChainedMsg*)call RadioPacket.getPayload(bufPtr, NULL);
    DelayChainedMsgs* sm = (DelayChainedMsgs*)call SerialPacket.getPayload(&serialPacket, NULL);
    sm->delay[rm->seqNo] = call Timer.getNow() - sendTime;
    call Leds.led1Toggle();
    return bufPtr;
  }
  
  event void AMSerialControl.startDone(error_t err) {
    call AMRadioControl.start();
  }

  event void AMSerialControl.stopDone(error_t err) {
    call RadioDutyCyclingControl.stop();
  }
  
  event void AMRadioControl.startDone(error_t err) {
    call RadioDutyCyclingControl.start();
  }
  event void AMRadioControl.stopDone(error_t err) {
  }

  event void RadioDutyCyclingControl.startDone(error_t err) {
  }
  event void RadioDutyCyclingControl.stopDone(error_t err) {
  }  

  event void RadioDutyCycling.beginOnTime() {
    ChainedMsg* m = (ChainedMsg*)call RadioPacket.getPayload(&radioPacket, NULL);
    call Leds.led0On();
    if(++(m->seqNo) < MAX_NUM_MESSAGES) {
      call AMRadioSend.send(SEND_TO_ADDR, &radioPacket, 50);
    }
    else if(m->seqNo == MAX_NUM_MESSAGES)
      call AMSerialSend.send(AM_BROADCAST_ADDR, &serialPacket, sizeof(DelayChainedMsgs));
  }
  event void RadioDutyCycling.beginOffTime() {
    call Leds.led0Off();
    call Timer.stop();
  }
}




