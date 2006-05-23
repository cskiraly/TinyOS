/* $Id: ForwardingEngineP.nc,v 1.1.2.12 2006-05-23 20:55:55 kasj78 Exp $ */
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
 *  @date   $Date: 2006-05-23 20:55:55 $
 */

#include <ForwardingEngine.h>
   
generic module ForwardingEngineP() {
  provides {
    interface Init;
    interface StdControl;
    interface Send[uint8_t client];
    interface Receive[collection_id_t id];
    interface Receive as Snoop[collection_id_t id];
    interface Intercept[collection_id_t id];
    interface Packet;
  }
  uses {
    interface AMSend as SubSend;
    interface Receive as SubReceive;
    interface Receive as SubSnoop;
    interface Packet as SubPacket;
    interface UnicastNameFreeRouting;
    interface SplitControl as RadioControl;
    interface Queue<fe_queue_entry_t*> as SendQueue;
    interface Pool<fe_queue_entry_t> as QEntryPool;
    interface Pool<message_t> as MessagePool;
    interface Timer<TMilli> as RetxmitTimer;
    interface PacketAcknowledgements;
    interface Random;
    interface RootControl;
    interface CollectionId[uint8_t client];
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

  enum {
    CLIENT_COUNT = uniqueCount(UQ_COLLECTION_CLIENT)
  };

  command error_t Init.init() {
    return SUCCESS;
  }

  command error_t StdControl.start() {
    running = TRUE;
    return SUCCESS;
  }

  command error_t StdControl.stop() {
    running = FALSE;
    return SUCCESS;
  }

  task void sendTask();
  
  event void RadioControl.startDone(error_t err) {
    if (err == SUCCESS) {
      radioOn = TRUE;
      if (!call SendQueue.empty()) {
        post sendTask();
      }
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
  
  event void RadioControl.stopDone(error_t err) {
    if (err == SUCCESS) {
      radioOn = FALSE;
    }
  }

  task void sendTask();

  network_header_t* getHeader(message_t* m) {
    return (network_header_t*)call SubPacket.getPayload(m, NULL);
  }
  
  command error_t Send.send[uint8_t client](message_t* msg, uint8_t len) {
    network_header_t* hdr;
    fe_queue_entry_t *qe;

    if (!running) {return EOFF;}
    
    call Packet.setPayloadLength(msg, len + sizeof(network_header_t));
    hdr = getHeader(msg);
    hdr->origin = TOS_NODE_ID;
    hdr->collectid = call CollectionId.fetch[client]();

    if (call QEntryPool.empty()) {
      // Queue pool is empty; fail the send.
      return EBUSY;
    }

    qe = call QEntryPool.get();
    qe->msg = msg;
    qe->client = client;
    
    if (call SendQueue.enqueue(qe) == SUCCESS) {
      if (radioOn && call SendQueue.size() == 1) {
        post sendTask();
      }
      return SUCCESS;
    }
    else {
      return FAIL;
    }
  }

  command error_t Send.cancel[uint8_t client](message_t* msg) {
    // XXX TODO: cancel not implemented yet.
    return FAIL;
  }

  command uint8_t Send.maxPayloadLength[uint8_t client]() {
    return call Packet.maxPayloadLength();
  }

  command void* Send.getPayload[uint8_t client](message_t* msg) {
    return call Packet.getPayload(msg, NULL);
  }

  
  // Note that we don't actually remove the packet from the
  // queue until it is successfully sent.
  task void sendTask() {
    if (!call UnicastNameFreeRouting.hasRoute() ||
         call SendQueue.empty() || 
         sending) {
      return;
    }
//    else if (call RootControl.isRoot()) {
//      loopback(); 
//    }
    else {
      error_t eval;
      fe_queue_entry_t* qe = call SendQueue.head();
      uint8_t payloadLen = call SubPacket.payloadLength(qe->msg);
      am_addr_t dest = call UnicastNameFreeRouting.nextHop();
      
      ackPending = (call PacketAcknowledgements.requestAck(qe->msg) == SUCCESS);
      
      eval = call SubSend.send(dest, qe->msg, payloadLen);
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
    fe_queue_entry_t *qe = call SendQueue.head();
    if (qe->msg != msg) {
      // Not our packet, something is very wrong...
      return;
    }
    else if (error != SUCCESS) {
      // immediate retransmission is the worst thing to do.
      // Retry in 512-1023 ms
      uint16_t r = call Random.rand16();
      r &= 0x1ff;
      r += 512;
      call RetxmitTimer.startOneShot(r);
    }
    // AckPending is for case when DL cannot support acks
    else if (ackPending && !call PacketAcknowledgements.wasAcked(msg)) {
      // immediate retransmission is the worst thing to do.
      // Retry in 128-255ms
      uint16_t r = call Random.rand16();
      r &= 0x7f;
      r += 128;
      call RetxmitTimer.startOneShot(r);
    }
    else if (getHeader(qe->msg)->origin == TOS_NODE_ID) {
      network_header_t* hdr;
      call SendQueue.dequeue();
      hdr = getHeader(qe->msg);
      if (qe->client < CLIENT_COUNT)
        signal Send.sendDone[qe->client](msg, SUCCESS);
      sending = FALSE;
      post sendTask();
    }
    else if (call MessagePool.size() < call MessagePool.maxSize()) {
      // A successfully forwarded packet.
      call MessagePool.put(qe->msg);
    }
    else {
      // It's a forwarded packet, but there's no room the pool;
      // someone has double-stored a pointer somewhere and we have nowhere
      // to put this, so we have to leak it...
    }
  }

  message_t* forward(message_t* m) {
    if (!call MessagePool.empty() && !call QEntryPool.empty()) {
      message_t* newMsg = call MessagePool.get();
      fe_queue_entry_t *qe = call QEntryPool.get();
      uint8_t len = call SubPacket.payloadLength(m);

      qe->msg = m;
      qe->client = CLIENT_COUNT;

      call Packet.setPayloadLength(m, len + sizeof(network_header_t));
      if (call SendQueue.enqueue(qe))
        return newMsg;
      else {
        call MessagePool.put(newMsg);
        call QEntryPool.put(qe);
      }
    }
    
    // We'll have to drop the packet on the floor: not enough
    // resources available to forward.
    return m;
  }
  
  event message_t* 
  SubReceive.receive(message_t* msg, void* payload, uint8_t len) {
    network_header_t* hdr = getHeader(msg);
    uint8_t netlen;
    collection_id_t collectid;
    collectid = hdr->collectid;

    // If I'm the root, signal receive. 
    if (call RootControl.isRoot())
      return signal Receive.receive[collectid](msg, 
                        call Packet.getPayload(msg, &netlen), 
                        call Packet.payloadLength(msg));
    // I'm on the routing path and Intercept indicates that I
    // should not forward the packet.
    else if (!signal Intercept.forward[collectid](msg, 
                        call Packet.getPayload(msg, &netlen), 
                        call Packet.payloadLength(msg)))
      return msg;
    else
      return forward(msg);
  }

  command void* 
  Receive.getPayload[collection_id_t id](message_t* msg, uint8_t* len) {
    return call Packet.getPayload(msg, NULL);
  }

  command uint8_t
  Receive.payloadLength[collection_id_t id](message_t *msg) {
    return call Packet.payloadLength(msg);
  }

  command void *
  Snoop.getPayload[collection_id_t id](message_t *msg, uint8_t *len) {
    return call Packet.getPayload(msg, NULL);
  }

  command uint8_t Snoop.payloadLength[collection_id_t id](message_t *msg) {
    return call Packet.payloadLength(msg);
  }

  event message_t* 
  SubSnoop.receive(message_t* msg, void *payload, uint8_t len) {
    network_header_t* hdr = getHeader(msg);
    return signal Snoop.receive[hdr->collectid] (msg, (void *)(hdr + 1), 
                                          len - sizeof(network_header_t));
  }
  
  event void RetxmitTimer.fired() {
    sending = FALSE;
    post sendTask();
  }
  
  command void Packet.clear(message_t* msg) {
    call SubPacket.clear(msg);
  }
  
  command uint8_t Packet.payloadLength(message_t* msg) {
    return call SubPacket.payloadLength(msg) - sizeof(network_header_t);
  }

  command void Packet.setPayloadLength(message_t* msg, uint8_t len) {
    call SubPacket.setPayloadLength(msg, len + sizeof(network_header_t));
  }
  
  command uint8_t Packet.maxPayloadLength() {
    return call SubPacket.maxPayloadLength() - sizeof(network_header_t);
  }

  command void* Packet.getPayload(message_t* msg, uint8_t* len) {
    uint8_t* payload = call SubPacket.getPayload(msg, len);
    if (len != NULL) {
      *len -= sizeof(network_header_t);
    }
    return payload + sizeof(network_header_t);
  }

  default event void
  Send.sendDone[uint8_t client](message_t *msg, error_t error) {
  }

  default event bool
  Intercept.forward[collection_id_t collectid](message_t* msg, void* payload, 
                                               uint16_t len) {
    return TRUE;
  }

  default event message_t *
  Receive.receive[collection_id_t collectid](message_t *msg, void *payload,
                                             uint8_t len) {
    return msg;
  }

  default event message_t *
  Snoop.receive[collection_id_t collectid](message_t *msg, void *payload,
                                           uint8_t len) {
    return msg;
  }

  default command collection_id_t CollectionId.fetch[uint8_t client]() {
    return 0;
  }
}
