/* $Id: QueueC.nc,v 1.1.2.1 2006-04-21 00:47:21 scipio Exp $ */
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

   
generic module QueueC(uint8_t QUEUE_SIZE, typedef queue_type) {
  provides {
    interface Queue<t>;
  }
}

implementation {

  queue_type queue[QUEUE_SIZE];
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

  command queue_type Queue.head() {
    return queue[head];
  }

  command queue_type Queue.pop() {
    queue_type t = call Queue.head();
    if (!Queue.empty()) {
      head++;
      head %= QUEUE_SIZE;
      size--;
    }
    return t;
  }

  command error_t Queue.push(queue_type newVal) {
    if (Queue.size() < Queue.maxSize()) {
      queue[tail] = newVal;
      tail++;
      size++;
      return SUCCESS;
    }
    else {
      return FAIL;
    }
  }
  
}
