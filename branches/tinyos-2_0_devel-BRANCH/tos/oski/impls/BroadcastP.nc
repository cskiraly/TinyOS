// $Id: BroadcastP.nc,v 1.1.2.1 2005-01-11 03:33:04 scipio Exp $
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
 * @date   January 5 2005
 */ 

includes Broadcast;

module BroadcastP {
  provides {
    interface Send[bcast_id id];
    interface Receive[bcast_id id];
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

  command error_t Send.send[bcast_id_t id](TOSMsg* msg, uint8_t len) {
    if (len > call Packet.maxPayloadLength()) {
      return ESIZE;
    }
    else {
      BroadcastMsg* bmsg = (BroadcastMsg*)getPayload(msg, NULL);
      bmsg->id = id;
      len += BROADCASTP_OFFSET;
      return call AMSend.send(msg, len, AM_BROADCAST_ADDR);
    }
  }

  command error_t Send.cancel[bcast_id_t id](TOSMsg* msg) {
    return call AMSend.cancel(msg);
  }

  event void AMSend.sendDone(TOSMsg* msg, error_t error) {
    BroadcastMsg* bmsg = (BroadcastMsg*)getPayload(msg, NULL);
    signal Send.sendDone[bmsg->id](msg, error);
  }

  event TOSMsg* SubReceive.receive(TOSMsg* msg,
				   void* payload,
				   uint8_t len) {
    BroadcastMsg* bmsg = (BroadcastMsg*)getPayload(msg, NULL);
    signal Receive.receive[bmsg->id](msg,
				     payload + BROADCASTP_OFFSET,
				     len - BROADCASTP_OFFSET); 
  }
  
  command void Packet.clear(TOS_Msg* msg) {
    uint8_t len;
    void* payload = call SubPacket.getPayload(msg, &len);
    memset(msg, len, 0);
  }

  command uint8_t Packet.payloadLength(TOSMsg* msg) {
    uint8_t len;
    void* payload = call SubPacket.getPayload(msg, &len);
    return len - BROADCASTP_OFFSET;
  }

  command uint8_t Packet.maxPayloadLength() {
    return call SubPacket.maxPayloadLength() - BROADCASTP_OFFSET;
  }

  command void* Packet.getPayload(TOSMsg* msg, uint8_t* len) {
    void* payload = call SubPacket.getPayload(msg, len);
    *len -= BROADCASTP_OFFSET;
    return payload + BROADCASTP_OFFSET;
  }

}
