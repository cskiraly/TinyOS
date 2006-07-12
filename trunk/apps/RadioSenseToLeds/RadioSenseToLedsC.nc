// $Id: RadioSenseToLedsC.nc,v 1.2 2006-07-12 16:59:10 scipio Exp $

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
 *  Implementation of the OSKI RadioSenseToLeds application. This
 *  application periodically broadcasts a reading from its platform's
 *  demo sensor, and displays broadcasts it hears on its LEDs. It displays
 *  the two most signficant bits of the value on LEDs 1 and 2; if there is
 *  an error, it lights LED 0.
 *
 *  @author Philip Levis
 *  @date   June 12 2005
 *
 **/

#include "Timer.h"
#include "RadioSenseToLeds.h"

module RadioSenseToLedsC {
  uses {
    interface Leds;
    interface Boot;
    interface Receive;
    interface AMSend;
    interface Timer<TMilli> as MilliTimer;
    interface Packet;
    interface Read<uint16_t>;
    interface SplitControl as RadioControl;
  }
}
implementation {

  message_t packet;
  bool locked = FALSE;
   
  event void Boot.booted() {
    call RadioControl.start();
  }

  event void RadioControl.startDone(error_t err) {
    if (err == SUCCESS) {
      call MilliTimer.startPeriodic(1000);
    }
  }
  event void RadioControl.stopDone(error_t err) {}
  
  event void MilliTimer.fired() {
    call Read.read();
  }

  event void Read.readDone(error_t result, uint16_t data) {
    if (locked) {
      return;
    }
    else {
      RadioSenseMsg* rsm;

      rsm = (RadioSenseMsg*)call Packet.getPayload(&packet, NULL);
      if (call Packet.maxPayloadLength() < sizeof(RadioSenseMsg)) {
	return;
      }
      rsm->error = result;
      rsm->data = data;
      if (call AMSend.send(AM_BROADCAST_ADDR, &packet, sizeof(RadioSenseMsg)) == SUCCESS) {
	locked = TRUE;
      }
    }
  }

  event message_t* Receive.receive(message_t* bufPtr, 
				   void* payload, uint8_t len) {
    call Leds.led1Toggle();
    if (len != sizeof(RadioSenseMsg)) {return bufPtr;}
    else {
      RadioSenseMsg* rsm = (RadioSenseMsg*)payload;
      uint16_t val = rsm->data;
      call Leds.led0Toggle();
      if (val & 0x8000) {
	call Leds.led1On();
      }
      else {
	call Leds.led1Off();
      }
      if (val & 0x4000) {
	call Leds.led2On();
      }
      else {
	call Leds.led2Off();
      }
      return bufPtr;
    }
  }

  event void AMSend.sendDone(message_t* bufPtr, error_t error) {
    if (&packet == bufPtr) {
      locked = FALSE;
    }
  }

}
