// $Id: SendQueueFifoC.nc,v 1.1.2.1 2005-08-08 04:07:55 scipio Exp $
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
 * @date  July 13 2005
 */ 

generic module SendQueueFifoM(uint8_t depth) {
  provides interface Source;
  uses interface Sink;
}

implementation {

  typedef struct SendQueueFifoMEntry {
    message_t* msg;
    uint8_t len;
  } SendQueueFifoMEntry;
  
  SendQueueFifoMEntry queue[depth];
  uint8_t cancelled[((depth + 7) / 8)];
  uint8_t head = 0;
  uint8_t tail = 0;
  uint8_t busy = FALSE;
  
  bool isFull() {
    return queue[tail].msg != NULL;
  }

  bool isEmpty() {
    return queue[head].msg == NULL;
  }

  void clearCancel(uint8_t index) {
    cancelled[index / 8] &= (~(0x80 >> (index % 8)));
  }
  
  void setCancel(uint8_t index) {
    cancelled[index / 8] |= (0x80 >> (index % 8));
  }

  bool isCancelled(uint8_t index) {
    return (cancelled[index / 8] & (0x80 >> (index % 8)));
  }
  
  command error_t Source.send(message_t* msg, uint8_t len) {
    // If there's no space (next free slot is in use), return EBUSY
    if (isFull()) {
      return EBUSY;
    }
    // Otherwise, put the message in the queue.
    else {
      queue[tail].msg = msg;
      queue[tail].len = len;
      clearCancel(tail);
      tail = ((tail + 1) % depth);
      post sendTask();
    }
  }

  command error_t cancel(message_t* msg) {
    uint8_t i;
    for (i = 0; i < depth; i++) {
      if (queue[i].msg == msg) {
	setCancel(i);
      }
    }
  }

  event void Sink.sendDone(message_t* msg, error_t err) {
    if
  }
  
