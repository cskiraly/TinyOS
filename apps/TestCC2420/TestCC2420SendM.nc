// $Id: TestCC2420SendM.nc,v 1.1.2.4 2006-01-29 20:30:58 scipio Exp $

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
 */

/**
 * @author Joe Polastre
 */
#include <message.h>
#include <CountMsg.h>
#include <Timer.h>

module TestCC2420SendM {
  uses interface Boot;
  uses interface Leds;
  uses interface SplitControl;
  uses interface Send;
  uses interface Timer<TMilli> as Timer1;
  uses interface RadioPacket;
}
implementation {

  message_t msg;
  uint16_t cnt;

  event void Boot.booted() {
    cnt = 0;
    // start the radio
    call SplitControl.start();
  }

  event void SplitControl.startDone(error_t error) { 
    call Timer1.startPeriodic(1024);
  }
  event void SplitControl.stopDone(error_t error) { }

  event void Timer1.fired() {
    CountMsg_t* cmsg = (CountMsg_t*)(call RadioPacket.getData(&msg) + 2);
    call Leds.led0Toggle();
    call RadioPacket.setAddress(&msg, 0xFFFF);
    // type location in tinyos 1.x
    msg.data[0] = AM_COUNT_MSG;
    // group location in tinyos 1.x
    msg.data[1] = DEF_TOS_AM_GROUP;
    cmsg->src = TOS_NODE_ID;
    cmsg->n = cnt++;
    if (call Send.send(&msg, sizeof(CountMsg_t))) {
      call Leds.led1On();
    }
  }

  event void Send.sendDone(message_t* _msg, error_t error) {
    call Leds.led2Toggle();
    if (error != SUCCESS) {
      cnt--;
    }
    else {
      call Leds.led1Off();
    }
  }

}


