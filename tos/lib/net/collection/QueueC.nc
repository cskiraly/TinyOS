/* $Id: QueueC.nc,v 1.1.2.7 2006-06-22 14:09:47 rfonseca76 Exp $ */
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
 *  @date   $Date: 2006-06-22 14:09:47 $
 */

   
generic module QueueC(typedef queue_t, uint8_t QUEUE_SIZE) {
  provides interface Queue<queue_t>;
}

implementation {

  queue_t queue[QUEUE_SIZE];
  uint8_t head = 0;
  uint8_t tail = 0;
  uint8_t size = 0;
  
  command bool Queue.empty() {
    return size == 0;
  }

  command uint8_t Queue.size() {
    return size;
  }

  command uint8_t Queue.maxSize() {
    return QUEUE_SIZE;
  }

  command queue_t Queue.head() {
    return queue[head];
  }

  void printQueue() {
#ifdef TOSSIM
    int i, j;
    dbg("QueueC", "head <-");
    for (i = head; i < head + size; i++) {
      dbg_clear("QueueC", "[");
      for (j = 0; j < sizeof(queue_t); j++) {
	uint8_t v = ((uint8_t*)&queue[i % QUEUE_SIZE])[j];
	dbg_clear("QueueC", "%0.2hhx", v);
      }
      dbg_clear("QueueC", "] ");
    }
    dbg_clear("QueueC", "<- tail\n");
#endif
  }
  
  command queue_t Queue.dequeue() {
    queue_t t = call Queue.head();
    dbg("QueueC", "%s: size is %hhu\n", __FUNCTION__, size);
    if (!call Queue.empty()) {
      head++;
      head %= QUEUE_SIZE;
      size--;
      printQueue();
    }
    return t;
  }

  command error_t Queue.enqueue(queue_t newVal) {
    if (call Queue.size() < call Queue.maxSize()) {
      dbg("QueueC", "%s: size is %hhu\n", __FUNCTION__, size);
      queue[tail] = newVal;
      tail++;
      tail %= QUEUE_SIZE;
      size++;
      printQueue();
      return SUCCESS;
    }
    else {
      return FAIL;
    }
  }
  
  command queue_t Queue.element(uint8_t index) {
    index += head;
    index %= QUEUE_SIZE;
    return queue[index];
  }  

}
