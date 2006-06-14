/* $Id: ForwardingEngineP.nc,v 1.1.2.17 2006-06-14 18:57:44 kasj78 Exp $ */
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
 *  @date   $Date: 2006-06-14 18:57:44 $
 */

#include <ForwardingEngine.h>
#include "CollectionDebugMsg.h"
   
generic module ForwardingEngineP() {
  provides {
    interface Init;
    interface StdControl;
    interface Send[uint8_t client];
    interface Receive[collection_id_t id];
    interface Receive as Snoop[collection_id_t id];
    interface Intercept[collection_id_t id];
    interface Packet;
    interface CollectionPacket;
  }
  uses {
    interface AMSend as SubSend;
    interface AMSend as DebugSend;
    interface Receive as SubReceive;
    interface Receive as SubSnoop;
    interface Packet as SubPacket;
    interface Packet as DebugPacket;
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
    interface AMPacket;
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

  /* Keeps track of whether we are currently sending to the UART a
   * debug message. */
  bool debugSendBusy = FALSE;

  enum {
    CLIENT_COUNT = uniqueCount(UQ_COLLECTION_CLIENT)
  };

  fe_queue_entry_t clientEntries[CLIENT_COUNT];
  fe_queue_entry_t* clientPtrs[CLIENT_COUNT];

  message_t loopbackMsg;
  message_t* loopbackMsgPtr;

  message_t debugMsg;
  CollectionDebugMsg *cdb; // pointer to the payload of the debug msg
  
  command error_t Init.init() {
    int i;
    for (i = 0; i < CLIENT_COUNT; i++) {
      clientPtrs[i] = clientEntries + i;
      dbg("Forwarder", "clientPtrs[%hhu] = %p\n", i, clientPtrs[i]);
    }
    loopbackMsgPtr = &loopbackMsg;
    cdb = (CollectionDebugMsg *)call DebugPacket.getPayload(&debugMsg, NULL);
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
    dbg("Forwarder", "%s: sending packet from client %hhu: %x, len %hhu\n", __FUNCTION__, client, msg, len);
    if (!running) {return EOFF;}
    
    call Packet.setPayloadLength(msg, len + sizeof(network_header_t));
    hdr = getHeader(msg);
    hdr->origin = TOS_NODE_ID;
    hdr->collectid = call CollectionId.fetch[client]();

    if (clientPtrs[client] == NULL) {
      dbg("Forwarder", "%s: send failed as client is busy.\n", __FUNCTION__);
      return EBUSY;
    }

    qe = clientPtrs[client];
    qe->msg = msg;
    qe->client = client;
    dbg("Forwarder", "%s: queue entry for %hhu is %hhu deep\n", __FUNCTION__, client, call SendQueue.size());
    if (call SendQueue.enqueue(qe) == SUCCESS) {
      if (radioOn && !call RetxmitTimer.isRunning()) {
        post sendTask();
      }
      clientPtrs[client] = NULL;
      return SUCCESS;
    }
    else {
      dbg("Forwarder", 
          "%s: send failed as packet could not be enqueued.\n", 
          __FUNCTION__);
      
      // send a debug message to the uart
      if (!debugSendBusy) {
        memset(cdb, 0, sizeof(CollectionDebugMsg));
        cdb->type = NET_C_FE_SEND_QUEUE_FULL;
        debugSendBusy = (call DebugSend.send(0xffff, &debugMsg,
          sizeof(CollectionDebugMsg)) == SUCCESS);
      }

      // Return the pool entry, as it's not for me...
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
    dbg("Forwarder", "%s: Trying to send a packet. Queue size is %hhu.\n", __FUNCTION__, call SendQueue.size());
    if (sending) {
      dbg("Forwarder", "%s: busy, don't send\n", __FUNCTION__);
      return;
    }
    else if (call SendQueue.empty()) {
      dbg("Forwarder", "%s: queue empty, don't send\n", __FUNCTION__);
      return;
    }
    else if (!call UnicastNameFreeRouting.hasRoute()) {
      dbg("Forwarder", "%s: no route, don't send, start retry timer\n", __FUNCTION__);
      call RetxmitTimer.startOneShot(10000);

      // send a debug message to the uart
      if (!debugSendBusy) {
        memset(cdb, 0, sizeof(CollectionDebugMsg));
        cdb->type = NET_C_FE_NO_ROUTE;
        debugSendBusy = (call DebugSend.send(0xffff, &debugMsg,
          sizeof(CollectionDebugMsg)) == SUCCESS);
      }

      return;
    }
    else {
      error_t eval;
      fe_queue_entry_t* qe = call SendQueue.head();
      uint8_t payloadLen = call SubPacket.payloadLength(qe->msg);
      am_addr_t dest = call UnicastNameFreeRouting.nextHop();
      dbg("Forwarder", "Sending queue entry %p\n", qe);
      if (call RootControl.isRoot()) {
	collection_id_t collectid = getHeader(qe->msg)->collectid;
	memcpy(loopbackMsgPtr, qe->msg, sizeof(message_t));
	ackPending = FALSE;
	
	dbg("Forwarder", "%s: I'm a root, so loopback and signal receive.\n", __FUNCTION__);
	loopbackMsgPtr = signal Receive.receive[collectid](loopbackMsgPtr,
							  call Packet.getPayload(loopbackMsgPtr, NULL), 
							  call Packet.payloadLength(loopbackMsgPtr));
	signal SubSend.sendDone(qe->msg, SUCCESS);
	return;
      }
      
      ackPending = (call PacketAcknowledgements.requestAck(qe->msg) == SUCCESS);
      
      eval = call SubSend.send(dest, qe->msg, payloadLen);
      if (eval == SUCCESS) {
	// Successfully submitted to the data-link layer.
	sending = TRUE;
	dbg("Forwarder", "%s: subsend succeeded with %p.\n", __FUNCTION__, qe->msg);
	if (qe->client < CLIENT_COUNT) {
	  dbg("Forwarder", "%s: client packet.\n", __FUNCTION__);
	}
	else {
	  dbg("Forwarder", "%s: forwarded packet.\n", __FUNCTION__);
	}
        return;
      }
      else if (eval == EOFF) {
	// The radio has been turned off underneath us. Assume that
	// this is for the best. When the radio is turned back on, we'll
	// handle a startDone event and resume sending.
        radioOn = FALSE;
	dbg("Forwarder", "%s: subsend failed from EOFF.\n", __FUNCTION__);
        // send a debug message to the uart
        if (!debugSendBusy) {
          memset(cdb, 0, sizeof(CollectionDebugMsg));
          cdb->type = NET_C_FE_SUBSEND_OFF;
          debugSendBusy = (call DebugSend.send(0xffff, &debugMsg,
            sizeof(CollectionDebugMsg)) == SUCCESS);
        }
      }
      else if (eval == EBUSY) {
	// This shouldn't happen, as we sit on top of a client and
        // control our own output; it means we're trying to
        // double-send (bug). This means we expect a sendDone, so just
        // wait for that: when the sendDone comes in, // we'll try
        // sending this packet again.	
	dbg("Forwarder", "%s: subsend failed from EBUSY.\n", __FUNCTION__);
        // send a debug message to the uart
        if (!debugSendBusy) {
          memset(cdb, 0, sizeof(CollectionDebugMsg));
          cdb->type = NET_C_FE_SUBSEND_BUSY;
          debugSendBusy = (call DebugSend.send(0xffff, &debugMsg,
            sizeof(CollectionDebugMsg)) == SUCCESS);
        }
      }
    }
  }

  void sendDoneBug() {
    // send a debug message to the uart
    if (!debugSendBusy) {
      memset(cdb, 0, sizeof(CollectionDebugMsg));
      cdb->type = NET_C_FE_BAD_SENDDONE;
      debugSendBusy = (call DebugSend.send(0xffff, &debugMsg,
        sizeof(CollectionDebugMsg)) == SUCCESS);
    }
  }

  event void DebugSend.sendDone(message_t *msg, error_t error) {
    debugSendBusy = FALSE;
  }

  event void SubSend.sendDone(message_t* msg, error_t error) {
    fe_queue_entry_t *qe = call SendQueue.head();
    dbg("Forwarder", "%s to %hu and %hhu\n", __FUNCTION__, call AMPacket.destination(msg), error);
    if (qe == NULL || qe->msg != msg) {
      dbg("Forwarder", "%s: BUG: not our packet (%p != %p)!\n", __FUNCTION__, msg, qe->msg);
      sendDoneBug();      // Not our packet, something is very wrong...
      return;
    }
    else if (error != SUCCESS) {
      // immediate retransmission is the worst thing to do.
      // Retry in 512-1023 ms
      uint16_t r = call Random.rand16();
      r &= 0x1ff;
      r += 512;
      call RetxmitTimer.startOneShot(r);
      dbg("Forwarder", "%s: send failed, retry in %hu ms\n", __FUNCTION__, r);
    }
    // AckPending is for case when DL cannot support acks
    else if (ackPending && !call PacketAcknowledgements.wasAcked(msg)) {
      // immediate retransmission is the worst thing to do.
      // Retry in 128-255ms
      uint16_t r = call Random.rand16();
      r &= 0x7f;
      r += 128;
      call RetxmitTimer.startOneShot(r);
      dbg("Forwarder", "%s: not acked, retry in %hu ms\n", __FUNCTION__, r);
    }
    else if (qe->client < CLIENT_COUNT) {
      network_header_t* hdr;
      uint8_t client = qe->client;
      dbg("Forwarder", "%s: our packet for client %hhu, remove %p from queue\n", __FUNCTION__, client, qe);
      clientPtrs[client] = qe;
      hdr = getHeader(qe->msg);
      call SendQueue.dequeue();
      signal Send.sendDone[client](msg, SUCCESS);
      sending = FALSE;
      post sendTask();
    }
    else if (call MessagePool.size() < call MessagePool.maxSize()) {
      // A successfully forwarded packet.
      dbg("Forwarder,Route", "%s: successfully forwarded packet (client: %hhu), message pool is %hhu/%hhu.\n", __FUNCTION__, qe->client, call MessagePool.size(), call MessagePool.maxSize());
      call SendQueue.dequeue();
      call MessagePool.put(qe->msg);
      //qe->msg = NULL;
      //qe->client = 255;
      call QEntryPool.put(qe);      
      sending = FALSE;
      post sendTask();
    }
    else {
      dbg("Forwarder", "%s: BUG: we have a pool entry, but the pool is full, client is %hhu.\n", __FUNCTION__, qe->client);
      sendDoneBug();    // It's a forwarded packet, but there's no room the pool;
      // someone has double-stored a pointer somewhere and we have nowhere
      // to put this, so we have to leak it...
    }
  }

  message_t* forward(message_t* m) {
    if (call MessagePool.empty()) {
      dbg("Route", "%s cannot forward, message pool empty.\n", __FUNCTION__);
      // send a debug message to the uart
      if (!debugSendBusy) {
        memset(cdb, 0, sizeof(CollectionDebugMsg));
        cdb->type = NET_C_FE_MSG_POOL_EMPTY;
        debugSendBusy = (call DebugSend.send(0xffff, &debugMsg,
          sizeof(CollectionDebugMsg)) == SUCCESS);
      }
    }
    else if (call QEntryPool.empty()) {
      dbg("Route", "%s cannot forward, queue entry pool empty.\n", 
          __FUNCTION__);
      // send a debug message to the uart
      if (!debugSendBusy) {
        memset(cdb, 0, sizeof(CollectionDebugMsg));
        cdb->type = NET_C_FE_QENTRY_POOL_EMPTY;
        debugSendBusy = (call DebugSend.send(0xffff, &debugMsg,
          sizeof(CollectionDebugMsg)) == SUCCESS);
      }
    }
    else {
      message_t* newMsg = call MessagePool.get();
      fe_queue_entry_t *qe = call QEntryPool.get();
      uint8_t len = call SubPacket.payloadLength(m);

      qe->msg = m;
      qe->client = 0xff;
      
      call Packet.setPayloadLength(m, len + sizeof(network_header_t));
      if (call SendQueue.enqueue(qe) == SUCCESS) {
	dbg("Forwarder,Route", "%s forwarding packet %p with queue size %hhu\n", __FUNCTION__, m, call SendQueue.size());
	if (!call RetxmitTimer.isRunning()) {
	  post sendTask();
	}
	return newMsg;
      }
      else {
        call MessagePool.put(newMsg);
        call QEntryPool.put(qe);
      }
    }

    // send a debug message to the uart
    if (!debugSendBusy) {
      memset(cdb, 0, sizeof(CollectionDebugMsg));
      cdb->type = NET_C_FE_SEND_QUEUE_FULL;
      debugSendBusy = (call DebugSend.send(0xffff, &debugMsg,
        sizeof(CollectionDebugMsg)) == SUCCESS);
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
    else {
      dbg("Route", "Forwarding packet from %hu.\n", hdr->origin);
      return forward(msg);
    }
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

  command am_addr_t CollectionPacket.getOrigin(message_t* msg) {
    return getHeader(msg)->origin;
  }
  
  command void CollectionPacket.setOrigin(message_t* msg, am_addr_t addr) {
    getHeader(msg)->origin = addr;
  }

  command uint8_t CollectionPacket.getCollectionID(message_t* msg) {
    return getHeader(msg)->collectid;
  }
  
  command void CollectionPacket.setCollectionID(message_t* msg, uint8_t id) {
    getHeader(msg)->collectid = id;
  }

  command uint8_t CollectionPacket.getControl(message_t* msg) {
    return getHeader(msg)->control;
  }
  
  command void CollectionPacket.setControl(message_t* msg, uint8_t control) {
    getHeader(msg)->control = control;
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
