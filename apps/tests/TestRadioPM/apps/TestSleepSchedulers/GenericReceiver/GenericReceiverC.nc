// $Id: GenericReceiverC.nc,v 1.1.2.1 2006-05-15 19:36:07 klueska Exp $

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

module GenericReceiverC {
  uses {
    interface SplitControl as AMSerialControl;
    interface SplitControl as AMRadioControl;
    interface Leds;
    interface Boot;
    interface Receive as RadioReceive;
    interface AMSend as AMSerialSend;
    interface Timer<TMilli> as MilliTimer;
    interface Packet as SerialPacket;
    interface Packet as RadioPacket;
//     interface LowPowerListening as Lpl;
//     interface RadioDutyCycling;
  }
}
implementation {

  #define TIMEOUT_LONG ((uint32_t)15000)
  #define NUM_TRIALS	5
  
  #define LPL_MODE	4
  #define SSS_ON_MODE   1
  #define SSS_OFF_MODE  1
  
  message_t packet;
  bool stopReceiving;
  int numTrials;
  
  void resetPackets() {
    int i;
    NumSenderMsgs* sm = (NumSenderMsgs*)call SerialPacket.getPayload(&packet, NULL);
    for(i=0; i<MAX_SENDERS; i++)
      sm->numMsgs[i] =0;
    call MilliTimer.startOneShot(TIMEOUT_LONG);
    stopReceiving = FALSE;
  }

  event void Boot.booted() {
    numTrials = 0;
//     call Lpl.setListeningMode(LPL_MODE);
//     call RadioDutyCycling.setModes(SSS_ON_MODE, SSS_OFF_MODE);
    call AMSerialControl.start();
  }
  
  event void MilliTimer.fired() {
    stopReceiving = TRUE;
    if(call AMSerialSend.send(AM_BROADCAST_ADDR, &packet, sizeof(NumSenderMsgs)) != SUCCESS)
      resetPackets();
  }

  event message_t* RadioReceive.receive(message_t* bufPtr, 
				   void* payload, uint8_t len) {
    if(stopReceiving == FALSE) {
      SenderAddrMsg* rm = (SenderAddrMsg*)call RadioPacket.getPayload(bufPtr, NULL);
      NumSenderMsgs* sm = (NumSenderMsgs*)call SerialPacket.getPayload(&packet, NULL);
      sm->numMsgs[rm->senderAddr]++;
      call Leds.led1Toggle();
    }
    return bufPtr;
  }

  event void AMSerialSend.sendDone(message_t* bufPtr, error_t error) {
    call Leds.led2Toggle();
//     call AMRadioControl.stop();
    if(numTrials++ < NUM_TRIALS) {
      resetPackets();
    }
  }

  event void AMSerialControl.startDone(error_t err) {
    call AMRadioControl.start();
  }
  event void AMSerialControl.stopDone(error_t err) {
    call AMSerialControl.start();
  }
  
  event void AMRadioControl.startDone(error_t err) {
    if(numTrials++ < NUM_TRIALS) {
          resetPackets();
    }
  }
  event void AMRadioControl.stopDone(error_t err) {
    call AMRadioControl.start();
  }

//   event void RadioDutyCycling.radioSwitchedOn() { call Leds.led0On(); }
//   event void RadioDutyCycling.radioSwitchedOff() { call Leds.led0Off(); }
}




