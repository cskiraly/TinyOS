// $Id: CC2420ActiveMessageP.nc,v 1.1.2.1 2005-08-29 00:46:56 scipio Exp $

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


/**
 * Active message implementation on top of the CC2420 radio. This
 * implementation uses the 16-bit addressing mode of 802.15.4: the
 * only additional byte it adds is the AM id byte, as the first byte
 * of the data payload.
 *
 * <pre>
 *   $Id: CC2420ActiveMessageP.nc,v 1.1.2.1 2005-08-29 00:46:56 scipio Exp $
 * </pre>

 * @author Philip Levis
 * @date   August 28 2005
 */

includes CC2420Const;

module CC2420ActiveMessageP {
  provides {
    interface AMSend[am_id_t id];
    interface Receive[am_id_t id];
    interface Receive as Snoop[am_id_t id];
    interface AMPacket;
    interface Packet;
  }
  uses {
    interface Send as SubSend;
    interface Receive as SubReceive;
    command am_addr_t amAddress();
  }
}
implementation {

  enum {
    CC2420_SIZE = MAC_HEADER_SIZE + MAC_FOOTER_SIZE,
  };
  
  CC2420Header* getHeader(message_t* amsg) {
    return (CC2420Header*)(amsg->data - sizeof(CC2420Header));
  }
  
  command error_t AMSend.send[am_id_t id](am_addr_t addr,
					  message_t* amsg,
					  uint8_t len) {
    CC2420Header* header = getHeader(amsg);
    header->type = id;
    header->addr = addr;
    header->destpan = TOS_AM_GROUP;
    return call SubSend.send(amsg, len + CC2420_SIZE);
  }

  command error_t AMSend.cancel[am_id_t id](message_t* msg) {
    return call SubSend.cancel(msg);
  }

  event void SubSend.sendDone(message_t* msg, error_t result) {
    signal AMSend.sendDone[call AMPacket.type(msg)](msg, result);
  }

  /* Receiving a packet */

  event message_t* SubReceive.receive(message_t* msg, void* payload, uint8_t len) {
    if (call AMPacket.isForMe(msg)) {
      return signal Receive.receive[call AMPacket.type(msg)](msg, payload, len - CC2420_SIZE);
    }
    else {
      return signal Snoop.receive[call AMPacket.type(msg)](msg, payload, len - CC2420_SIZE);
    }
  }
  
  command am_addr_t AMPacket.address() {
    return call amAddress();
  }
 
  command am_addr_t AMPacket.destination(message_t* amsg) {
    CC2420Header* header = getHeader(amsg);
    return header->addr;
  }

  command bool AMPacket.isForMe(message_t* amsg) {
    return (call AMPacket.destination(amsg) == call AMPacket.address() ||
	    call AMPacket.destination(amsg) == AM_BROADCAST_ADDR);
  }

  command am_id_t AMPacket.type(message_t* amsg) {
    CC2420Header* header = getHeader(amsg);
    return header->type;
  }

  //command am_group_t AMPacket.group(message_t* amsg) {
  //  return amsg->header.group;
  //}
  
 default event message_t* Receive.receive[am_id_t id](message_t* msg, void* payload, uint8_t len) {
    return msg;
  }
  
  default event message_t* Snoop.receive[am_id_t id](message_t* msg, void* payload, uint8_t len) {
    return msg;
  }

 default event void AMSend.sendDone[uint8_t id](message_t* msg, error_t err) {
   return;
 }

 
 command void Packet.clear(message_t* msg) {}
 
 command uint8_t Packet.payloadLength(message_t* msg) {
   return getHeader(msg)->length - CC2420_SIZE;
 }
 
 command uint8_t Packet.maxPayloadLength() {
   return TOSH_DATA_LENGTH;
 }
 
 command void* Packet.getPayload(message_t* msg, uint8_t* len) {
   if (len != NULL) {
     *len = call Packet.payloadLength(msg);
   }
   return msg->data;
 }


}
