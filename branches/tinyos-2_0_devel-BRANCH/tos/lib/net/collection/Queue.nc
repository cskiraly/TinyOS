/* $Id: Queue.nc,v 1.1.2.3 2006-06-22 13:43:28 rfonseca76 Exp $ */
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
 *  @author Kyle Jamieson
 *  @date   $Date: 2006-06-22 13:43:28 $
 */

   
interface Queue<t> {

  command bool empty();
  command uint8_t size();
  command uint8_t maxSize();

  /**
   * Get the head of the queue without removing it. If the queue
   * is empty, the return value is undefined.
   *
   * @return The head of the queue.
   */
  command t head();
  
  /**
   * Remove the head of the queue. If the queue is empty, the return
   * value is undefined.
   *
   * @return The head of the queue.
   */
  command t dequeue();

  /**
   * Enqueue an element to the tail of the queue.
   *
   * @param newVal - the element to enqueue
   * @return SUCCESS if the element was enqueued successfully, FAIL
   *                 if it was not enqueued.
   */
  command error_t enqueue(t newVal);

  /**
   * Return the nth element of the queue without dequeueing it, 
   * where 0 is the head of the queue and (size - 1) is the tail. 
   * If the element requested is larger than the current queue size,
   * the return value is undefined.
   *
   * @param index - the index of the element to return
   * @return the requested element in the queue.
   */
  command t element(uint8_t index);
}
