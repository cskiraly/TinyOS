// $Id: ActiveMessageM.nc,v 1.1.2.2 2005-01-18 22:25:06 scipio Exp $

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
 * Date last modified:  $Id: ActiveMessageM.nc,v 1.1.2.2 2005-01-18 22:25:06 scipio Exp $
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

  enum {
    AM_HEADER_SIZE = sizeof(AMHeader);
  };
  
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
    if (!active) {
      return EOFF;
    }
    else {
      void* payload = call SubPacket.getPayload(msg, NULL);
      AMHeader* header = (AMHeader*)payload;
      
      header->type = id;
      header->addr = addr;
      len += AM_HEADER_SIZE;
      
      return call SubSend.send(msg, len);
    }
  }

  command error_t AMSend.cancel[am_id_t id](TOSMsg* msg) {
    if (!active) {
      return EOFF;
    }
    else {
      return call SubSend.cancel(msg);
    }
  }

  event void SubSend.sendDone(TOSMsg* msg, error_t result) {
    void* payload = call SubPacket.getPayload(msg, NULL);
    AMHeader* header = (AMHeader*)payload;
    signal Send.sendDone[header->type](msg, result);
  }


  /* Receiving a packet */

  event TOSMsg* SubReceive.receive(TOSMsg* msg, void* payload, uint8_t len) {
    if (!active) {
      return msg;
    }
    else {
      AMHeader* header = (AMHeader*)payload;
      uint8_t* payloadPtr = (uint8_t*)payload;
      
      /* Move payload pointer forward and adjust length. */
      payloadPtr += AM_HEADER_SIZE;
      len -= AM_HEADER_SIZE;
      
      if (call AMPacket.isForMe(msg)) {
	return signal Receive.receive[header->type](msg, payloadPtr, len);
      }
      else {
	return signal Snoop.receive[header->type](msg, payloadPtr, len);
      }
    }
  }
  
  
  default event TOSMsg* Receive.receive[am_id_t id](TOSMsg* msg, void* payload, uint8_t len) {
    return msg;
  }
  
  default event TOSMsg* Snoop.receive[am_id_t id](TOSMsg* msg, void* payload, uint8_t len) {
    return msg;
  }

  
 /* Packet interface */
  
  command void Packet.clear(TOSMsg* msg) {
    call SubPacket.clear(msg);
  }

  command uint8_t Packet.payloadLength(TOSMsg* msg) {
    uint8_t len = call SubPacket.payloadLength(msg);
    len -= AM_HEADER_SIZE;
    return len;
  }

  command uint8_t Packet.maxPayloadLength() {
    return call SubPacket.maxPayloadLength() - AM_HEADER_SIZE;
  }

  command void* Packet.getPayload(TOSMsg* msg, uint8_t* len) {
    uint8_t* payloadPtr = call SubPacket.getPayload(msg, len);

    payloadPtr += AM_HEADER_SIZE;
    if (len != NULL) {
      *len -= AM_HEADER_SIZE;
    }

    return (void*)payloadPtr;
  }
  
}
