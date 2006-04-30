/* $Id: ForwardingEngineP.nc,v 1.1.2.5 2006-04-30 17:53:56 scipio Exp $ */
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
 *  @date   $Date: 2006-04-30 17:53:56 $
 */

   
generic module ForwardingEngineP() {
  provides {
    interface Init;
    interface StdControl;
    interface Send[collection_id_t id];
    interface Receive[collection_id_t id];
    interface Receive as Snoop[collection_id_t id];
    interface Intercept[collection_id_t id];
    interface Packet;
  }
  uses {
    interface AMSend;
    interface AMReceive as SubReceive;
    interface AMReceive as SubSnoop;
    interface Packet as SubPacket;
    interface UnicastNameFreeRouting;
    interface SplitControl as RadioControl;
    interface Queue<message_t*> as SendQueue;
    interface Pool<message_t> as ForwardPool;
    interface Timer<TMilli> as SendTimer;
    interface PacketAcknowledgments;
    interface Random;
    interface RootControl;
  }
}
implementation {

  /* Keeps track of whether the routing layer is running; if not,
   * it will not send packets. */
  bool running = FALSE;

  /* Keeps track of whether the radio is on; no sense sending packets
   * if the radio is off. */
  bool radioOn = FALSE;

  /* Keeps track of whether an ack is pending on an outgoing packet,
   * so that the engine can work unreliably when the data-link layer
   * does not support acks. */
  bool ackPending = FALSE;

  /* Keeps track of whether the packet on the head of the queue
   * is being used, and control access to the data-link layer.*/
  bool sending = FALSE;
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

  event void UnicastNameFreeRouting.routeFound() {
    post sendTask();
  }

  event void UnicastNameFreeRouting.noRoute() {
    // Depend on the sendTask to take care of this case;
    // if there is no route the component will just resume
    // operation on the routeFound event
  }
  
  event void RadioControl.stopDone() {
    radioOn = FALSE;
  }

  task void sendTask();

  network_header_t* getHeader(message_t* m) {
    return (network_header_t*)call SubPacket.getPayload(m, NULL);
  }
  
  command error_t Send.send[collection_id_t id](message_t* msg, uint8_t len) {
    network_header_t* hdr;
    if (!running) {return EOFF;}
    
    call Packet.setPayloadLength(msg, len + sizeof(network_header_t));
    hdr = getHeader(msg);
    hdr->origin = TOS_NODE_ID;
    hdr->id = id;
    
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
    if (!call UnicastNameFreeRouting.hasRoute() ||
	call Queue.isEmpty() ||
	sending) {
      return;
    }
    else if (call RootControl.isRoot()) {
      loopback();
    }
    else {
      error_t eval;
      message_t* msg = call Queue.head();
      uint8_t payloadLen = call SubPacket.payloadLen(msg);
      am_addr_t dest = call UnicastNameFreeRouting.nextHop();
      
      ackPending = (call PacketAcknowledgments.requestAck(msg) == SUCCESS);
      
      eval = call AMSend.send(dest, msg, payloadLen);
      if (eval == SUCCESS) {
	// Successfully submitted to the data-link layer.
	sending = TRUE;
        return;
      }
      if (eval == EOFF) {
	// The radio has been turned off underneath us. Assume that
	// this is for the best. When the radio is turned back on, we'll
	// handle a startDone event and resume sending.
        radioOn = FALSE;
      }
      if (eval == EBUSY) {
        // This shouldn't happen, as we sit on top of a client and
        // control our own output; it means we're trying to
        // double-send (bug). This means we expect a sendDone, so just
        // wait for that: when the sendDone comes in, // we'll try
        // sending this packet again.
      }
    }
  }

  event void SubSend.sendDone(message_t* msg, error_t error) {
    if (msg != call SendQueue.head()) {
      // Not our packet, something is very wrong...
      return;
    }
    else if (error != SUCCESS) {
      // immediate retransmission is the worst thing to do.
      // Retry in 512-1023 ms
      uint16_t r = call Random.rand16();
      r &= 0x1ff;
      r += 512;
      call SendTimer.startOneShot(r);
    }
    // AckPending is for case when DL cannot support acks
    else if (ackPending && !call PacketAcknowledgments.wasAcked(msg)) {
      // immediate retransmission is the worst thing to do.
      // Retry in 128-255ms
      uint16_t r = call Random.rand16();
      r &= 0x7f;
      r += 128;
      call SendTimer.startOneShot(r);
    }
    else if (getHeader(msg)->origin == TOS_NODE_ID) {
      network_header_t* hdr;
      msg = call SendQueue.pop();
      hdr = getHeader(msg);
      signal Send.sendDone[hdr->id](msg, SUCCESS);
      sending = FALSE;
      post sendTask();
    }
    else if (call Pool.size() < Pool.maxSize()) {
      // A successfully forwarded packet.
      call Pool.put(msg);
    }
    else {
      // It's a forwarded packet, but there's no room the pool;
      // someone has double-stored a pointer somewhere and we have nowhere
      // to put this, so we have to leak it...
    }
  }

  message_t* forward(message_t* m) {
    if (call Pool.isEmpty() ||
	call SendQueue.push(m) != SUCCESS) {
      // No forwarding entries free, or the send queue is full;
      // the latter should never occur without the former, unless
      // someone is submitting more packets than they should.
      return m;
    }
    else {
      message_t* newMsg = call Pool.get();
      uint8_t len = call SubPacket.payloadLength(m);x
      call Packet.setPayloadLength(m, len + sizeof(network_header_t));
      call Queue.push(m);
      return newMsg;
    }
  }
  
  event message_t* SubReceive.receive(message_t* msg, void* payload, uint8_t len) {
    if (call AMPacket.isForMe(msg)) {
      // Three cases:
      //   1) I'm the root, signal receive
      //   2) I'm on the routing path, but suppress the packet
      //   3) In on the routing path, and forward it
      if (call RootControl.isRoot()) {
	network_header_t* hdr = getHeader(msg);
	return signal Receive.receive(msg, call Packet.getPayload(msg), call Packet.payloadLength(msg));
      }
      else if (!signal Intercept.intercept(msg, call Packet.getPayload(msg), call Packet.payloadLength(msg))) {
	return msg;
      }
      else {
	return forward(msg);
      }
    }
  }

  event message_t* SubSnoop.receive(message_t* msg) {
    network_header_t* hdr = getHeader(msg);
    return Snoop.receive[hdr->id](msg);
  }
  
  event void SendTimer.fired() {
    sending = FALSE;
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
