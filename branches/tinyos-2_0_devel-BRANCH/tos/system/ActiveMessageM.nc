// $Id: ActiveMessageM.nc,v 1.1.2.1 2005-01-18 18:46:34 scipio Exp $

/*									tab:4
 * "Copyright (c) 2004-2005 The Regents of the University  of California.  
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
 * Copyright (c) 2004-2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
/*
 *
 * Authors:		Philip Levis
 * Date last modified:  $Id: ActiveMessageM.nc,v 1.1.2.1 2005-01-18 18:46:34 scipio Exp $
 *
 */

/**
 * @author Philip Levis
 * @date January 17 2005
 */

configuration ActiveMessageM {
  provides {
    interface SplitControl;

    interface AMSend[am_id_t id];
    interface Receive[am_id_t id];
    interface Receive as Snoop[am_id_t id];
  
    interface Packet;
    interface AMPacket;
  }
  uses {
    interface SplitControl as SubControl;
    interface Send as SubSend;
    interface Receive as SubReceive;
    interface Packet as SubPacket;
  }
}
implementation {

  bool active = FALSE;

  /* Starting and stopping ActiveMessages. */
  command error_t SplitControl.start() {
    return call SubControl.start();
  }

  event void SubControl.startDone() {
    active = TRUE;
    signal SplitControl.startDone();
  }

  command error_t SplitControl.stop() {
    return call SubControl.stop();    
  }

  event void SubControl.stopDone() {
    active = FALSE;
    signal SplitControl.stopDone();
  }


  /* Sending a packet */
  
  command error_t AMSend.send[am_id_t id](am_addr_t addr, TOSMsg* msg, uint8_t len) {

  }

  command error_t AMSend.cancel[am_id_t id](TOSMsg* msg) {

  }

  event void SubSend.sendDone(TOSMsg* msg, error_t result) {

  }


  /* Receiving a packet */

  event TOSMsg* SubReceive.receive(TOSMsg* msg, void* payload, uint8_t len) {
    AMHeader* header = (AMHeader*)payload;
    if (call AMPacket.isForMe(msg)) {
      return signal Receive.receive[header->type](msg, payload + sizeof(AMHeader), len - sizeof(AMHeader));
    }
    else {
      return signal Snoop.receive[header->type](msg, payload + sizeof(AMHeader), len - sizeof(AMHeader));
    }
  }

  /* Packet information */


  
}
