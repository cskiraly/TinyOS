// $Id: SendQueueFifoC.nc,v 1.1.2.1 2005-08-07 20:33:57 scipio Exp $
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
 * The OSKI send queue abstraction, following a FIFO policy.
 *
 * @author Philip Levis
 * @date   January 5 2005
 */ 

generic module SendQueueFifoC(uint8_t depth) {
  provides {
    interface Send;
  }
  uses {
    interface Send as SubSend;
  }
}

implementation {

  typedef struct SendQueueEntry {
    TOSMsg* msg;       // NULL if entry is empty
    uint8_t len;
    uint8_t cancelled:1;
    uint8_t sent:1;
    uint8_t cleaned:1; // Used in cleanQueue
  } SendQueueEntry;
  
  QueueEntry* queue[depth];
  uint8_t head = 0;
  uint8_t tail = 0;
  bool busy = FALSE;

  bool isEmpty() {
    return (queue[head] == NULL);
  }

  bool isFull() {
    return (queue[tail] != NULL);
  }
  
  /* Scan through queue, signalling cancellation for any
   * cancelled packets and removing them from the queue. Shift
   * uncancelled entries appropriately and update the tail index
   * if needed. */
  void cleanQueue() {
    uint8_t i, cleanCount;

    /* Find cancelled send requests, and signal that they are
       cancelled. Mark them cleaned for queue compaction. */
    for (i = head; i < head + depth; i++) {
      uint8_t index = i % depth;
      if (queue[index].cancelled && queue[index].msg != NULL) {
	signal Send.sendDone(queue[index].msg, ECANCEL);
	queue[index].cleaned = TRUE;
	queue[index].msg = NULL;
      }
    }

    cleanCount = 0;
    /* Queue compaction. Remove all cleaned entries and
     * shift others left. Index is the location we're looking
     * at, properIndex is the index it should be.*/
    for (i = head; i < head + depth; i++) {
      uint8_t index = i % depth;

      if (queue[index].cleaned) {
	cleanCount++;
      }
      else if (cleanCount) { /* Copy entry down, and clear old entry. */
	uint8_t properIndex = (i - cleanCount) % depth;
	nmemcpy(&queue[properIndex], &queue[index], sizeof(SendQueueEntry));
	queue[index].msg = NULL;
      }
      else {
	// Do nothing, no compaction needed (yet)
      }
    }

    /* If entries have been cleaned, then adjust the tail index
       to denote the shorter queue. */
    tail = (tail + depth - cleanCount) % depth;
  }

  bool sendNext() {
    if (isEmpty()) {
      return FALSE;
    }
    else if (call SubSend.send(queue[head].msg, queue[head].len) == SUCCESS) {
      queue[head].sent = TRUE;
      return SUCCESS;
    }
    else {
      return FAIL;
    }
  }
  
  task void sendTask() {
    cleanQueue();
    if (sendNext()) {
      busy = TRUE;
    }
    else {
      busy = FALSE;
    }
  }

  command error_t Send.send(TOSMsg* msg, uint8_t len) {
    // If there's no space (next free slot is in use), return EBUSY
    if (isFull()) {
      return EBUSY;
    }
    // Otherwise, put the message in the queue.
    else {
      queue[tail].msg = msg;
      queue[tail].len = len;
      queue[tail].cancelled = FALSE;
      queue[tail].sent = FALSE;
      queue[tail].cleaned = FALSE;
      if (!busy) {
	post sendTask();
      }
      tail = ((tail + 1) % depth);
    }
  }

  command error_t Send.cancel(TOSMsg* msg) {
    uint8_t i;
    /* If the message is still in the queue, cancel it. If it's being
       sent, then try cancelling the underlying send; otherwise,
       just mark it as cancelled */
    for (i = head; i != tail; i = ((i + 1) % depth)) {
      if (queue[i].msg == msg) {
	queue[i].cancelled = TRUE;
	if (queue[i].sent) {
	  return call SubSend.cancel(msg);
	}
	else {
	  return SUCCESS;
	}
      }
    }
    else {
      return FALSE;
    }
  }

  event void SubSend.sendDone(TOSMsg* msg, error_t error) {
    if (queue[head].msg == msg) {
      queue[head].msg = NULL;
      head = (head + 1) % depth;
      signal Send.sendDone(msg, error);
      if (isEmpty()) {
	busy = FALSE;
      }
      else {
	post sendTask();
      }
    }
  }

}
