/* $Id: ForwardingEngineP.nc,v 1.1.2.1 2006-04-21 00:47:21 scipio Exp $ */
/*
 * "Copyright (c) 2006 Stanford University. All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and
 * its documentation for any purpose, without fee, and without written
 * agreement is hereby granted, provided that the above copyright
 * notice, the following two paragraphs and the author appear in all
 * copies of this software.
 * 
 * IN NO EVENT SHALL STANFORD UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES
 * ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN
 * IF STANFORD UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
 * DAMAGE.
 * 
 * STANFORD UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE
 * PROVIDED HEREUNDER IS ON AN "AS IS" BASIS, AND STANFORD UNIVERSITY
 * HAS NO OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES,
 * ENHANCEMENTS, OR MODIFICATIONS."
 */

/*
 *  @author Philip Levis
 *  @date   $Date: 2006-04-21 00:47:21 $
 */

   
generic module ForwardingEngineP() {
  provides {
    interface Init;
    interface StdControl;
    interface Send;
    interface Receive;
    interface Receive as Snoop;
    interface Intercept;
    interface Packet;
  }
  uses {
    interface AMSend;
    interface AMReceive;
    interface Packet as SubPacket;
    interface BasicRouting;
    interface SplitControl as RadioControl;
    interface Queue<message_t*> as SendQueue;
    interface Timer<TMilli> as SendTimer;
    interface PacketAcknowledgments;
  }
}

implementation {
  
  bool running = FALSE;
  bool radioOn = FALSE;
  bool ackPending = FALSE;
  typedef nx_uint8_t collection_id_t;
  
  typedef nx_struct network_header_t {
    nx_am_addr_t origin;
    collection_id_t id;
  } network_header_t;
 
  
  command error_t Init.init() {}

  command error_t StdControl.start() {
    running = TRUE;
    return SUCCESS;
  }

  command error_t StdControl.stop() {
    running = FALSE;
    return SUCCESS;
  }

  event void RadioControl.startDone() {
    radioOn = TRUE;
    if (!Queue.isEmpty()) {
      post sendTask();
    }
  }
  
  event void RadioControl.stopDone() {
    radioOn = FALSE;
  }

  task void sendTask();
  
  command error_t Send.send(message_t* msg, uint8_t len) {
    if (!running) {return EOFF;}
    
    call Packet.setPayloadLength(msg, len);
    if (call SendQueue.push(msg) == SUCCESS) {
      if (radioOn && call SendQueue.size() == 1) {
        post sendTask();
      }
      return SUCCESS;
    }
    else {
      return FAIL;
    }
  }
  
  // Note that we don't actually remove the packet from the
  // queue until it is successfully sent.
  task void sendTask() {
    error_t eval;
    if (!call Queue.isEmpty()) {
      message_t* msg = call Queue.head();
      uint8_t payloadLen = call SubPacket.payloadLen(msg);
      am_addr_t dest = AM_BROADCAST_ADDR;
      // do routing mojo here
      ackPending = (call PacketAcknowledgments.requestAck(msg) == SUCCESS);
      
      eval = call AMSend.send(dest, msg, payloadLen);
      if (eval == SUCCESS) {
        return;
      }
      if (eval == EOFF) {
        radioOn = FALSE;
      }
      if (eval == EBUSY) {
        // This shouldn't happen, as we sit on top of a client
        // and control our own output; it means we're trying
        // to double-send. This means we expect a sendDone,
        // so just wait for that.
      }
    }
  }

  event void sendDone(message_t* msg, error_t error) {
    if (msg != call SendQueue.head()) {
      // Not our packet, something is very wrong...
      return;
    }
    else if (error != SUCCESS) {
      post sendTask();
    }
    else if (call PacketAcknowledgments.wasAcked(msg)) {
      msg = call SendQueue.pop();
      // signal our send done here
      post sendTask();
    }
    else {
      // This will become something a bit more variable
      // Assumption is that if ack failed on the selected
      // route, there might be congesion, etc., and
      // the le/routing engine can compensate, but
      // immediate retransmission is the worst thing to do.
      call SendTimer.startOneShot(100);
    }
  }
  
  event void SendTimer.fired() {
    post sendTask();
  }
  
  command uint8_t Send.maxPayloadLength() {
    return Packet.maxPayloadLength();
  }

  command void* Send.getPayload(message_t* msg) {
    return Packet.getPayload(msg, NULL);
  }

  command void Packet.clear(message_t* msg) {
    call SubPacket.clear(msg);
  }
  
  command uint8_t Packet.payloadLength(message_t* msg) {
    return SubPacket.payloadLength(msg) - sizeof(network_header_t);
  }
  command uint8_t Packet.setPayloadLength(message_t* msg, uint8_t len) {
    call SubPacket.setPayloadLength(msg, len + sizeof(network_header_t));
  }
  command uint8_t Packet.maxPayloadLength() {
    return SubPacket.maxPayloadLength() - sizeof(network_header_t);
  }
  command void* Packet.getPayload(message_t* msg, uint8_t* len) {
    uint8_t* payload = call SubPacket.getPayload(msg, len);
    if (len != NULL) {
      *len -= sizeof(network_header_t);
    }
    return payload + sizeof(network_header_t);
  }
  
  
}
