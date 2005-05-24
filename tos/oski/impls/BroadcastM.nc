// $Id: BroadcastM.nc,v 1.1.2.3 2005-05-24 23:01:05 scipio Exp $
/*									tab:4
 * "Copyright (c) 2005 The Regents of the University  of California.  
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
 * Copyright (c) 2004 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */


/**
 * The implementation of OSKI broadcasts, which build on top of Active
 * Messages to add another level of dispatch for address-free packets.
 * Note that this implementation is not as efficient as it could be:
 * all packets contain an address, even though it's always a
 * broadcast. Alternative implementations could involve being
 * underneath AM, which adds addressing; there are interactions
 * with hardware on many of these issues, however (e.g., hardware
 * address filtering).
 *
 * @author Philip Levis
 * @date   May 16 2005
 */ 

includes Broadcast;

module BroadcastM {
  provides {
    interface Send[uint8_t id];
    interface Receive[uint8_t id];
    interface Packet;
  }
  uses {
    interface AMSend;
    interface Receive as SubReceive;
    interface Packet as SubPacket;
    interface AMPacket;
  }
  
}

implementation {

  enum {
    BROADCASTP_OFFSET = offsetof(BroadcastMsg, data),
  };

  command error_t Send.send[uint8_t id](message_t* msg, uint8_t len) {
    if (len > call Packet.maxPayloadLength()) {
      return ESIZE;
    }
    else {
      BroadcastMsg* bmsg = (BroadcastMsg*)call SubPacket.getPayload(msg, NULL);
      bmsg->id = id;
      len += BROADCASTP_OFFSET;
      return call AMSend.send(AM_BROADCAST_ADDR, msg, len);
    }
  }

  command error_t Send.cancel[uint8_t id](message_t* msg) {
    return call AMSend.cancel(msg);
  }

  event void AMSend.sendDone(message_t* msg, error_t error) {
    BroadcastMsg* bmsg = (BroadcastMsg*)call SubPacket.getPayload(msg, NULL);
    signal Send.sendDone[bmsg->id](msg, error);
  }

  event message_t* SubReceive.receive(message_t* msg,
				      void* payload,
				      uint8_t len) {
    BroadcastMsg* bmsg = (BroadcastMsg*)call SubPacket.getPayload(msg, NULL);
    return signal Receive.receive[bmsg->id](msg,
					    payload + BROADCASTP_OFFSET,
					    len - BROADCASTP_OFFSET); 
  }
  
  command void Packet.clear(message_t* msg) {
    uint8_t len;
    void* payload = call SubPacket.getPayload(msg, &len);
    memset(msg, len, 0);
  }

  command uint8_t Packet.payloadLength(message_t* msg) {
    uint8_t len;
    void* payload = call SubPacket.getPayload(msg, &len);
    return len - BROADCASTP_OFFSET;
  }

  command uint8_t Packet.maxPayloadLength() {
    return call SubPacket.maxPayloadLength() - BROADCASTP_OFFSET;
  }

  command void* Packet.getPayload(message_t* msg, uint8_t* len) {
    uint8_t* payload = call SubPacket.getPayload(msg, len);
    *len -= BROADCASTP_OFFSET;
    return payload + BROADCASTP_OFFSET;
  }

 default event void Send.sendDone[uint8_t id](message_t* msg,
					      error_t error) {return;}

 default event message_t* Receive.receive[uint8_t id](message_t* msg,
						      void* payload,
						      uint8_t len) {
   return msg;
 }
}
