// $Id: SendQueueFIFOP.nc,v 1.1.2.1 2005-01-18 18:46:29 scipio Exp $
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

generic module SendQueueFIFOP(uint8_t depth) {
  provides {
    interface Send;
  }
  uses {
    interface Send as SubSend;
  }
}

implementation {

  typedef struct SendQueueEntry {
    TOSMsg* msg;
    uint8_t len;
    bool cancelled;
  }
  
  TOSMsg* queue[depth];
  uint8_t head = 0;
  uint8_t tail = 0;
  bool busy = FALSE;
  
  task void sendTask() {

  }

  command error_t Send.send(TOSMsg* msg, uint8_t len) {
    // If there's no space (next free slot is in use), return EBUSY
    if (((tail + 1) % depth) == head) {
      return EBUSY;
    }
    // Otherwise, put the message in the queue.
    else {
      queue[tail].msg = msg;
      queue[tail].len = len;
      queue[tail].cancelled = FALSE;
      if (!busy) {
	post sendTask();
      }
      tail = ((tail + 1) % depth);
    }
  }

  command error_t Send.cancel(TOSMsg* msg) {
    uint8_t i;
    // See if the message is still in the queue.
    for (i = head; i != tail; i = ((i + 1) % depth)) {
      if (queue[i].msg == msg) {
	// If so, then cancel it and post a cancelling task
	queue[i].cancelled = TRUE;
	post cancelTask();
	return SUCCESS;
      }
    }
    else {
      return FALSE;
    }
  }

  event void SubSend.sendDone(TOSMsg* msg, error_t error) {

  }

}
