/* $Id: LinkEstimatorP.nc,v 1.1.2.1 2006-04-25 05:27:21 gnawali Exp $ */
/*
 * "Copyright (c) 2006 University of Southern California.
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written
 * agreement is hereby granted, provided that the above copyright
 * notice, the following two paragraphs and the author appear in all
 * copies of this software.
 *
 * IN NO EVENT SHALL THE UNIVERSITY OF SOUTHERN CALIFORNIA BE LIABLE TO
 * ANY PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL
 * DAMAGES ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS
 * DOCUMENTATION, EVEN IF THE UNIVERSITY OF SOUTHERN CALIFORNIA HAS BEEN
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * THE UNIVERSITY OF SOUTHERN CALIFORNIA SPECIFICALLY DISCLAIMS ANY
 * WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE
 * PROVIDED HEREUNDER IS ON AN "AS IS" BASIS, AND THE UNIVERSITY OF
 * SOUTHERN CALIFORNIA HAS NO OBLIGATION TO PROVIDE MAINTENANCE,
 * SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 */

/*
 @ authors Omprakash Gnawali
 @ Created: April 24, 2006
 */


#include "Timer.h"

module LinkEstimatorP {
  provides {
    interface AMSend as Send;
    interface Receive;
    interface LinkEstimator;
    interface Init;
    interface Packet;
  }

  uses {
    interface AMSend;
    interface AMPacket as SubAMPacket;
    interface Packet as SubPacket;
    interface Receive as SubReceive;
    interface Timer<TMilli>;
  }
}

implementation {

#define NEIGHBOR_TABLE_SIZE 10
#define NEIGHBOR_AGE_TIMER 4096

  // neighbor table
  typedef struct neighbor_table_entry {
    am_addr_t ll_addr;
    uint8_t lastseq;
    uint8_t rcvcnt;
    uint8_t failcnt;
    uint8_t age;
    uint8_t flags;
    uint8_t inquality;
    uint8_t outquality;
  } neighbor_table_entry_t;
 
  // for outgoing link estimator message
  // so that we can compute bi-directional quality
  typedef nx_struct neighbor_stat_entry {
    nx_am_addr_t ll_addr;
    nx_int8_t inquality;
  } neighbor_stat_entry_t;
  
  // link estimator header added to
  // every message passing thru' the link estimator
  typedef nx_struct linkest_header {
    nx_am_addr_t ll_addr;
    nx_uint8_t seq;
  } linkest_header_t;

  neighbor_table_entry_t NeighborTable[NEIGHBOR_TABLE_SIZE];
  uint8_t linkEstSeq = 0;
  uint8_t numNeighbors = 0;
  message_t neighborTablePkt;

  linkest_header_t* getHeader(message_t* m) {
    return (linkest_header_t*)call SubPacket.getPayload(m, NULL);
  }

  uint8_t addLinkEstHeader(message_t *msg, uint8_t len) {
    uint8_t newlen;
    linkest_header_t *hdr;

    newlen = len + sizeof(linkest_header_t);
    call Packet.setPayloadLength(msg, newlen);
    hdr = getHeader(msg);
    hdr->ll_addr = TOS_NODE_ID; //link id, but TOS_NODE_ID for now
    hdr->seq = linkEstSeq++;
    return newlen;
  }

  // Either a timer or a command will trigger this
  void send_neighbor_table() {
    neighbor_stat_entry_t* entry;
    uint8_t pktlen;
    char* buf;

    buf = (char *) call Packet.getPayload(&neighborTablePkt, NULL);
    entry = (neighbor_stat_entry_t *)buf;
    // dump NeighborTable[0..n-1] to entry,
    // one by one, getting next slot in the payload
    pktlen = addLinkEstHeader(&neighborTablePkt, numNeighbors * sizeof(neighbor_stat_entry_t));
    call AMSend.send(AM_BROADCAST_ADDR, &neighborTablePkt, pktlen);
  }

  uint8_t searchNeighbor(uint16_t nodeid) {
    // return idx to NeighborTable
    return 0;
  }

  void ageNeighbors() {
    // increment age for each neighbor
    // time out neighbors
  }

  uint8_t computeBidirLinkQuality(uint8_t inQuality, uint8_t outQuality) {
    // estimator specific function to compute bi-directional quality
    return 0;
  }

  command error_t Init.init() {
    dbg("LI", "Link estimator init\n");
    call Timer.startOneShot(NEIGHBOR_AGE_TIMER);
    return SUCCESS;
  }

  event void Timer.fired() {
    dbg("LI", "Linkestimator timer fired\n");
    ageNeighbors();
    call Timer.startOneShot(NEIGHBOR_AGE_TIMER);
  }

  command uint8_t LinkEstimator.getLinkQuality(uint16_t neighbor) {
    // call searchNeighbor
    // return computeBidirLinkQuality(NeighborTable[..].inquality,
    //                                NeighborTable[..].outquality)
    return 0;
  }

  command uint8_t LinkEstimator.getReverseQuality(uint16_t neighbor) {
    // call searchNeighbor
    // return NeighborTable[..].inquality
    return 0;
  }

  command uint8_t LinkEstimator.getForwardQuality(uint16_t neighbor) {
    // call searchNeighbor
    // return NeighborTable[..].outquality
    return 0;
  }

  command error_t Send.send(am_addr_t addr, message_t* msg, uint8_t len) {
    uint8_t newlen;
    newlen = addLinkEstHeader(msg, len);
    return call AMSend.send(addr, msg, newlen);
  }

  event void AMSend.sendDone(message_t* msg, error_t error ) {
    return signal Send.sendDone(msg, error);
  }

  command uint8_t Send.cancel(message_t* msg) {
    return call AMSend.cancel(msg);
  }

  command uint8_t Send.maxPayloadLength() {
    return call Packet.maxPayloadLength();
  }

  command void* Send.getPayload(message_t* msg) {
    return call Packet.getPayload(msg, NULL);
  }

  event message_t* SubReceive.receive(message_t* msg, void* payload, uint8_t len) {
    if (call SubAMPacket.destination(msg) == AM_BROADCAST_ADDR) {
      linkest_header_t* hdr = getHeader(msg);
      dbg("LI", "Got seq: %d from link: %d\n", hdr->seq, hdr->ll_addr);
      // update neighbor table with this information
    }
    // we need to send hdr->ll_addr to the routing layer, don't know how to do that.
    return signal Receive.receive(msg, call Packet.getPayload(msg, NULL), call Packet.payloadLength(msg));
  }

  command void* Receive.getPayload(message_t* msg, uint8_t* len) {
    return call Packet.getPayload(msg, len);
  }

  command uint8_t Receive.payloadLength(message_t* msg) {
    return call Packet.payloadLength(msg);
  }

  command void Packet.clear(message_t* msg) {
    call SubPacket.clear(msg);
  }

  command uint8_t Packet.payloadLength(message_t* msg) {
    return call SubPacket.payloadLength(msg) - sizeof(linkest_header_t);
  }

  command void Packet.setPayloadLength(message_t* msg, uint8_t len) {
    call SubPacket.setPayloadLength(msg, len + sizeof(linkest_header_t));
  }

  command uint8_t Packet.maxPayloadLength() {
    return call SubPacket.maxPayloadLength() - sizeof(linkest_header_t);
  }

  command void* Packet.getPayload(message_t* msg, uint8_t* len) {
    uint8_t* payload = call SubPacket.getPayload(msg, len);
    if (len != NULL) {
      *len -= sizeof(linkest_header_t);
    }
    return payload + sizeof(linkest_header_t);
  }
}

