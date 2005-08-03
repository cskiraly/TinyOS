// $Id: TestSerialM.nc,v 1.1.2.5 2005-08-03 00:00:31 bengreenstein Exp $

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
 * Test application for the UART, strictly byte-level.
 *
 * @author Gilman Tolle
 **/

includes Timer;

module TestSerialM { 
  uses {
    interface Leds;
    interface Boot;
    interface Receive;
    interface Send;
  }
}
implementation {

  message_t buf;
  message_t *bufPtr = &buf;
  bool locked = FALSE;

  event void Boot.booted() {
    bufPtr = &buf;
  }

  event message_t* Receive.receive(message_t* msg, 
                                   void* payload, uint8_t len) {
    message_t *swap;
    
    // net.tinyos.tools.Send 5 4 2 1 3 6 7
    if ((msg->header.addr == 0x0504) &&
        msg->header.length == 0x02 &&
        msg->header.group == 0x01 &&
        msg->header.type == 0x03 &&
        msg->data[0] == 6 &&
        msg->data[1] == 7) call Leds.led0Toggle();

    if (!locked) {
      locked = TRUE;
      swap = bufPtr;
      bufPtr = msg;
      if (call Send.send(bufPtr, len) == SUCCESS){
        call Leds.led1Toggle();
      }
      return swap;
    } 
    else {
      return msg;
    }
  }
  
  event void Send.sendDone(message_t* msg, error_t error) {
    if (msg == bufPtr){
      locked = FALSE;
      call Leds.led2Toggle();
    }
  }
}  
  



