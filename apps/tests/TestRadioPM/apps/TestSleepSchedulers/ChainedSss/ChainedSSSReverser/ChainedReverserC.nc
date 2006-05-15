// $Id: ChainedReverserC.nc,v 1.1.2.1 2006-05-15 19:36:07 klueska Exp $

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

module ChainedReverserC {
  uses {
    interface SplitControl as AMRadioControl;
    interface SplitControl as RadioDutyCyclingControl;
    interface Leds;
    interface Boot;
    interface Receive as RadioReceive;
    interface AMSend as AMRadioSend;
    interface Packet as RadioPacket;
    interface AMPacket;
    interface RadioDutyCycling;
  }
}
implementation {

#define SEND_TO_ADDR (call AMPacket.address()-1)

  message_t radioPacket;

  event void Boot.booted() {
    call RadioDutyCycling.setModes(CURRENT_DUTY_CYCLE_ON, CURRENT_DUTY_CYCLE_OFF);
    call AMRadioControl.start();
  }

  event void AMRadioSend.sendDone(message_t* bufPtr, error_t error) {
    call Leds.led2Toggle();
  }

  event message_t* RadioReceive.receive(message_t* bufPtr, 
           void* payload, uint8_t len) {
    ChainedMsg* rm = (ChainedMsg*)call RadioPacket.getPayload(bufPtr, NULL);
    rm->goingForward = FALSE;
    call Leds.led1Toggle();
    call AMRadioSend.send(SEND_TO_ADDR, bufPtr, TOSH_DATA_LENGTH);
    return &radioPacket;
  }
  
  event void AMRadioControl.startDone(error_t err) {
    call RadioDutyCyclingControl.start();
  }
  event void AMRadioControl.stopDone(error_t err) {
    call RadioDutyCyclingControl.stop();
  }

  event void RadioDutyCyclingControl.startDone(error_t err) {
  }
  event void RadioDutyCyclingControl.stopDone(error_t err) {
  }  

  event void RadioDutyCycling.beginOnTime() {
    call Leds.led0On();
  }
  event void RadioDutyCycling.beginOffTime() {
    call Leds.led0Off();
  }
}




