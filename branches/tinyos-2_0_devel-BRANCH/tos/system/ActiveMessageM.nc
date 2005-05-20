// $Id: ActiveMessageM.nc,v 1.1.2.3 2005-05-20 00:25:01 scipio Exp $

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
 * Date last modified:  $Id: ActiveMessageM.nc,v 1.1.2.3 2005-05-20 00:25:01 scipio Exp $
 *
 */

/**
 * @author Philip Levis
 * @date January 17 2005
 */

module ActiveMessageM {
  provides {
    interface Init;
    interface SplitControl;

    interface AMSend[am_id_t id];
    interface Receive[am_id_t id];
    interface Receive as Snoop[am_id_t id];
  
    interface Packet;
    interface AMPacket;
  }
  uses {
    interface Init as SubInit;
    interface SplitControl as SubControl;
    interface Send as SubSend;
    interface Receive as SubReceive;
    interface Packet as SubPacket;
  }
}
implementation {

  bool active = FALSE;

  command error_t Init.init() {
    return call SubInit.init();
  }
  
  /* Starting and stopping ActiveMessages. */
  command error_t SplitControl.start() {
    return call SubControl.start();
  }

  event void SubControl.startDone(error_t error) {
    if (error == SUCCESS) {
      active = TRUE;
    }
    signal SplitControl.startDone(error);
  }

  command error_t SplitControl.stop() {
    return call SubControl.stop();    
  }

  event void SubControl.stopDone(error_t error) {
    if (error == SUCCESS) {
      active = FALSE;
    }
    signal SplitControl.stopDone(error);
  }


  /* Sending a packet */
  
  command error_t AMSend.send[am_id_t id](am_addr_t addr, message_t* msg, uint8_t len) {
    if (!active) {
      return EOFF;
    }
    else {
      void* payload = call SubPacket.getPayload(msg, NULL);
      AMHeader* header = (AMHeader*)payload;
      
      header->type = id;
      msg->header.addr = addr;
      len += AM_HEADER_SIZE;
      
      return call SubSend.send(msg, len);
    }
  }

  command error_t AMSend.cancel[am_id_t id](message_t* msg) {
    if (!active) {
      return EOFF;
    }
    else {
      return call SubSend.cancel(msg);
    }
  }

  event void SubSend.sendDone(message_t* msg, error_t result) {
    void* payload = call SubPacket.getPayload(msg, NULL);
    AMHeader* header = (AMHeader*)payload;
    signal AMSend.sendDone[header->type](msg, result);
  }


  /* Receiving a packet */

  event message_t* SubReceive.receive(message_t* msg, void* payload, uint8_t len) {
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
  
  
  default event message_t* Receive.receive[am_id_t id](message_t* msg, void* payload, uint8_t len) {
    return msg;
  }
  
  default event message_t* Snoop.receive[am_id_t id](message_t* msg, void* payload, uint8_t len) {
    return msg;
  }

  
 /* Packet interface */
  
  command void Packet.clear(message_t* msg) {
    call SubPacket.clear(msg);
  }

  command uint8_t Packet.payloadLength(message_t* msg) {
    uint8_t len = call SubPacket.payloadLength(msg);
    len -= AM_HEADER_SIZE;
    return len;
  }

  command uint8_t Packet.maxPayloadLength() {
    return call SubPacket.maxPayloadLength() - AM_HEADER_SIZE;
  }

  command void* Packet.getPayload(message_t* msg, uint8_t* len) {
    uint8_t* payloadPtr = call SubPacket.getPayload(msg, len);

    payloadPtr += AM_HEADER_SIZE;
    if (len != NULL) {
      *len -= AM_HEADER_SIZE;
    }

    return (void*)payloadPtr;
  }

  /* AMPacket interface. */
  
  command am_addr_t AMPacket.localAddress() {
    return TOS_LOCAL_ADDRESS;
  }
 
  command am_addr_t AMPacket.destination(message_t* amsg) {
    return amsg->header.addr;
    //AMHeader* header = (AMHeader*)call SubPacket.getPayload(amsg, NULL);
    //return header->dest;
  }

  command bool AMPacket.isForMe(message_t* amsg) {
    return (call AMPacket.destination(amsg) == call AMPacket.localAddress() ||
	    call AMPacket.destination(amsg) == AM_BROADCAST_ADDR);
  }
 
  command bool AMPacket.isAMPacket(message_t* amsg) {
    return SUCCESS;
  }

 default event void AMSend.sendDone[uint8_t id](message_t* msg, error_t err) {
   return;
 }
}
