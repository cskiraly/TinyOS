/* $Id: LinkEstimatorP.nc,v 1.1.2.4 2006-05-02 01:37:10 gnawali Exp $ */
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
 @ author Omprakash Gnawali
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
    interface LinkSrcPacket;
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
#define NEIGHBOR_AGE_TIMER 8192

  enum {
    VALID_ENTRY = 0x1,
    EVICT_QUALITY_THRESHOLD = 0x20,
    MAX_AGE = 6,
    MAX_PKT_GAP = 10,
    MAX_QUALITY = 0xff,
    INVALID_RVAL = 0xff,
    INVALID_NEIGHBOR_ADDR = 0xff,
    INFINITY = 0xff,
    ALPHA = 2 // (out of 10, thus 0.2)
  };

  // neighbor table
  typedef struct neighbor_table_entry {
    am_addr_t ll_addr;
    uint8_t lastseq;
    uint8_t rcvcnt;
    uint8_t failcnt;
    uint8_t flags;
    uint8_t inage;
    uint8_t outage;
    uint8_t inquality;
    uint8_t outquality;
  } neighbor_table_entry_t;

  // for outgoing link estimator message
  // so that we can compute bi-directional quality
  typedef nx_struct neighbor_stat_entry {
    nx_am_addr_t ll_addr;
    nx_int8_t inquality;
  } neighbor_stat_entry_t;
  
  typedef nx_struct linkest_footer {
    nx_uint16_t num_entries;
    neighbor_stat_entry_t neighborList[1];
  } linkest_footer_t;

  // link estimator header added to
  // every message passing thru' the link estimator
  typedef nx_struct linkest_header {
    nx_am_addr_t ll_addr;
    nx_uint8_t seq;
    nx_uint8_t linkest_footer_offset;
  } linkest_header_t;

  neighbor_table_entry_t NeighborTable[NEIGHBOR_TABLE_SIZE];
  uint8_t linkEstSeq = 0;
  uint8_t numNeighbors = 0;
  message_t neighborTablePkt;

  linkest_header_t* getHeader(message_t* m) {
    return (linkest_header_t*)call SubPacket.getPayload(m, NULL);
  }

  linkest_footer_t* getFooter(message_t* m, uint8_t len) {
    return (linkest_footer_t*)(len + (uint8_t *)call Packet.getPayload(m,NULL));
  }

  uint8_t addLinkEstHeaderAndFooter(message_t *msg, uint8_t len) {
    uint8_t newlen;
    linkest_header_t *hdr;
    linkest_footer_t *footer;
    uint8_t i, j;
    dbg("LI", "newlen1 = %d\n", len);
    newlen = len + sizeof(linkest_header_t) + sizeof(linkest_footer_t);
    call Packet.setPayloadLength(msg, newlen);
    hdr = getHeader(msg);
    footer = getFooter(msg, len);
    footer->num_entries = 0;
    j = 0;
    for (i = 0; i < NEIGHBOR_TABLE_SIZE; i++) {
      if (NeighborTable[i].flags & VALID_ENTRY) {
	footer->neighborList[j].ll_addr = NeighborTable[i].ll_addr;
	footer->neighborList[j].inquality = NeighborTable[i].inquality;

	dbg("LI", "Loaded on footer: %d %d %d\n", j, footer->neighborList[j].ll_addr,
	    footer->neighborList[j].inquality);

	j = ++footer->num_entries;

      }
    }

    hdr->ll_addr = call SubAMPacket.address();
    hdr->seq = linkEstSeq++;
    hdr->linkest_footer_offset = sizeof(linkest_header_t) + len;
    dbg("LI", "newlen2 = %d\n", newlen);
    if (j > 0) {
      newlen += j * sizeof(neighbor_stat_entry_t);
    }
    dbg("LI", "newlen3 = %d\n", newlen);
    return newlen;
  }


  uint8_t computeBidirLinkQuality(uint8_t inQuality, uint8_t outQuality) {
    return ((inQuality * outQuality) >> 8);
  }


  void initNeighborIdx(uint8_t i, am_addr_t ll_addr) {
    neighbor_table_entry_t *ne;
    ne = &NeighborTable[i];
    ne->ll_addr = ll_addr;
    ne->lastseq = 0;
    ne->rcvcnt = 0;
    ne->failcnt = 0;
    ne->flags = VALID_ENTRY;
    ne->inage = 0;
    ne->outage = 0;
    ne->inquality = 0;
    ne->outquality = 0;
  }
 
  uint8_t findIdx(am_addr_t ll_addr) {
    uint8_t i;
    for (i = 0; i < NEIGHBOR_TABLE_SIZE; i++) {
      if (NeighborTable[i].flags & VALID_ENTRY) {
	if (NeighborTable[i].ll_addr == ll_addr) {
	  return i;
	}
      }
    }
    return INVALID_RVAL;
  }

  uint8_t findEmptyNeighborIdx() {
    uint8_t i;
    for (i = 0; i < NEIGHBOR_TABLE_SIZE; i++) {
      if (NeighborTable[i].flags & VALID_ENTRY) {
      } else {
	return i;
      }
    }
      return INVALID_RVAL;
  }

  uint8_t findWorstNeighborIdx() {
    uint8_t i, worstNeighborIdx, worstQuality, thisQuality;

    worstNeighborIdx = INVALID_RVAL;
    worstQuality = MAX_QUALITY;
    for (i = 0; i < NEIGHBOR_TABLE_SIZE; i++) {
      if (NeighborTable[i].flags & VALID_ENTRY) {
	thisQuality = computeBidirLinkQuality(NeighborTable[i].inquality,
					      NeighborTable[i].outquality);
	if ((thisQuality < worstQuality) && (thisQuality < EVICT_QUALITY_THRESHOLD)) {
	  worstNeighborIdx = i;
	  worstQuality = thisQuality;
	}
      }
    }
    return worstNeighborIdx;
  }

  void updateReverseQuality(am_addr_t neighbor, uint8_t outquality) {
    uint8_t idx;
    idx = findIdx(neighbor);
    if (idx != INVALID_RVAL) {
      NeighborTable[idx].outquality = outquality;
      NeighborTable[idx].outage = MAX_AGE;
    }
  }

  void updateNeighborEntryIdx(uint8_t idx, uint8_t seq) {
    uint8_t packetGap;

    packetGap = seq - NeighborTable[idx].lastseq;
    dbg("LI", "updateNeighborEntryIdx: prevseq %d, curseq %d, gap %d\n",
	NeighborTable[idx].lastseq, seq, packetGap);
    NeighborTable[idx].lastseq = seq;
    NeighborTable[idx].rcvcnt++;
    NeighborTable[idx].inage = MAX_AGE;
    if (packetGap > 0) {
      NeighborTable[idx].failcnt += packetGap - 1;
    }
    if (packetGap > MAX_PKT_GAP) {
      NeighborTable[idx].failcnt = 0;
      NeighborTable[idx].rcvcnt = 1;
      NeighborTable[idx].outage = 0;
      NeighborTable[idx].outquality = 0;
      NeighborTable[idx].inquality = 0;
    }
  }


  void updateNeighborTableEst() {
    uint8_t i, totalPkt;
    neighbor_table_entry_t *ne;
    uint8_t newEst;
    
    for (i = 0; i < NEIGHBOR_TABLE_SIZE; i++) {
      ne = &NeighborTable[i];
      if (ne->flags & VALID_ENTRY) {
	if (ne->inage > 0)
	  ne->inage--;
	if (ne->outage > 0)
	  ne->outage--;

	if ((ne->inage == 0) && (ne->outage == 0)) {
	  ne->flags ^= VALID_ENTRY;
	} else {
	  totalPkt = ne->rcvcnt + ne->failcnt;
	  if (totalPkt == 0) {
	    ne->inquality = (ALPHA * ne->inquality) / 10;
	  } else {
	    newEst = (255 * ne->rcvcnt) / totalPkt;
	    ne->inquality = (ALPHA * ne->inquality + (10-ALPHA) * newEst)/10;
	  }
	  ne->rcvcnt = 0;
	  ne->failcnt = 0;
	}
      }
    }
  }

  void print_neighbor_table() {
    uint8_t i, totalPkt;
    neighbor_table_entry_t *ne;
    for (i = 0; i < NEIGHBOR_TABLE_SIZE; i++) {
      ne = &NeighborTable[i];
      if (ne->flags & VALID_ENTRY) {
	dbg("LI", "%d:%d inQ=%d, inA=%d, outQ=%d, outA=%d, rcv=%d, fail=%d, biQ=%d\n",
	    i, ne->ll_addr, ne->inquality, ne->inage, ne->outquality, ne->outage,
	    ne->rcvcnt, ne->failcnt, computeBidirLinkQuality(ne->inquality, ne->outquality));
      }
    }
  }

  void initNeighborTable() {
    uint8_t i;

    for (i = 0; i < NEIGHBOR_TABLE_SIZE; i++) {
      NeighborTable[i].flags = 0;
    }
  }

  command error_t Init.init() {
    uint8_t i;
    dbg("LI", "Link estimator init\n");
    initNeighborTable();
    call Timer.startPeriodic(NEIGHBOR_AGE_TIMER);
    return SUCCESS;
  }

  event void Timer.fired() {
    dbg("LI", "Linkestimator timer fired\n");
    print_neighbor_table();
    updateNeighborTableEst();
    print_neighbor_table();
  }

  // EETX (Extra Expected number of Transmission)
  // EETX = ETX - 1
  // computeEETX returns EETX*10

  uint8_t computeEETX(uint8_t q1) {
    uint16_t q;
    if (q1 > 0) {
      q =  2550 / q1 - 10;
      if (q > 255) {
	q = INFINITY;
      }
      return (uint8_t)q;
    } else {
      return INFINITY;
    }
  }

  uint8_t computeBidirEETX(uint8_t q1, uint8_t q2) {
    uint16_t q;
    if ((q1 > 0) && (q2 > 0)) {
      q =  65025 / q1;
      q = (10*q) / q2 - 10;
      if (q > 255) {
	q = INFINITY;
      }
      return (uint8_t)q;
    } else {
      return INFINITY;
    }
  }


  command uint8_t LinkEstimator.getLinkQuality(uint16_t neighbor) {
    uint8_t idx;
    idx = findIdx(neighbor);
    if (idx == INVALID_RVAL) {
      return INFINITY;
    } else {
      return computeBidirEETX(NeighborTable[idx].inquality,
			      NeighborTable[idx].outquality);
    };
  }

  command uint8_t LinkEstimator.getReverseQuality(uint16_t neighbor) {
    uint8_t idx;
    idx = findIdx(neighbor);
    if (idx == INVALID_RVAL) {
      return INFINITY;
    } else {
      return computeEETX(NeighborTable[idx].inquality);
    };
  }

  command uint8_t LinkEstimator.getForwardQuality(uint16_t neighbor) {
    uint8_t idx;
    uint16_t q;
    idx = findIdx(neighbor);
    if (idx == INVALID_RVAL) {
      return INFINITY;
    } else {
      return computeEETX(NeighborTable[idx].outquality);
    };
  }

  command am_addr_t LinkSrcPacket.getSrc(message_t* msg) {
    linkest_header_t* hdr = getHeader(msg);
    return hdr->ll_addr;
  }

  command error_t Send.send(am_addr_t addr, message_t* msg, uint8_t len) {
    uint8_t newlen;
    newlen = addLinkEstHeaderAndFooter(msg, len);
    dbg("LI", "Sending seq: %d\n", linkEstSeq);
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

  event message_t* SubReceive.receive(message_t* msg,
				      void* payload,
				      uint8_t len) {
    uint8_t nidx;
    if (call SubAMPacket.destination(msg) == AM_BROADCAST_ADDR) {
      linkest_header_t* hdr = getHeader(msg);
      linkest_footer_t* footer;
      dbg("LI", "Got seq: %d from link: %d\n", hdr->seq, hdr->ll_addr);

      print_neighbor_table();

      // update neighbor table with this information
      nidx = findIdx(hdr->ll_addr);
      if (nidx == INVALID_RVAL) {
	nidx = findEmptyNeighborIdx();
	initNeighborIdx(nidx, hdr->ll_addr);
      }
      if (nidx == INVALID_RVAL) {
	nidx = findWorstNeighborIdx();
	signal LinkEstimator.evicted(NeighborTable[nidx].ll_addr);
	dbg("LI", "Going to replace neighbor idx: %d\n", nidx);
	if (nidx != INVALID_RVAL) {
	  initNeighborIdx(nidx, hdr->ll_addr);
	}
      }
      if (nidx != INVALID_RVAL) {
	updateNeighborEntryIdx(nidx, hdr->seq);
      }

      if (hdr->linkest_footer_offset > 0) {
	dbg("LI", "There is a linkest footer in this packet: %d\n", hdr->linkest_footer_offset);
	footer = (linkest_footer_t*) (hdr->linkest_footer_offset +
				      (uint8_t *)call SubPacket.getPayload(msg, NULL));

	dbg("LI", "Number of footer entries: %d\n", footer->num_entries);

	{
	  uint8_t i, my_ll_addr;
	  my_ll_addr = call SubAMPacket.address();
	  for (i = 0; i < footer->num_entries; i++) {
	    dbg("LI", "%d %d %d\n", i, footer->neighborList[i].ll_addr,
		footer->neighborList[i].inquality);
	    if (footer->neighborList[i].ll_addr == my_ll_addr) {
	      updateReverseQuality(hdr->ll_addr, footer->neighborList[i].inquality);
	    }
	  }
	}

      }

    }
    
    return signal Receive.receive(msg,
				  call Packet.getPayload(msg, NULL),
				  call Packet.payloadLength(msg));
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

