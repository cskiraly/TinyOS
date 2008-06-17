// $Id: TestBroadcastC.nc,v 1.1.4.2 2006-05-15 18:35:24 klueska Exp $

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
 *  Implementation of the OSKI TestBroadcast application.
 *
 *  @author Philip Levis
 *  @date   May 16 2005
 *
 **/

#include "Timer.h"

module TestBroadcastC {
  uses {
    interface Leds;
    interface Boot;
    interface Receive;
    interface Send;
    interface Timer<TMilli> as MilliTimer;
    interface Service;
  }
}
implementation {

  message_t packet;
  bool locked;
  
  event void Boot.booted() {
    call Service.start();
    call MilliTimer.startPeriodic(1000);
  }

  event void MilliTimer.fired() {
    if (locked) {
      return;
    }
    else if (call Send.send(&packet, 6) == SUCCESS) {
      call Leds.led0On();
      locked = TRUE;
    }
  }
  
  event message_t* Receive.receive(message_t* bufPtr, 
				   void* payload, uint8_t len) {
     call Leds.led1Toggle();
     return bufPtr;
  }

  event void Send.sendDone(message_t* bufPtr, error_t error) {
    if (&packet == bufPtr) {
      call Leds.led0Off();
      locked = FALSE;
    }
  }
}



