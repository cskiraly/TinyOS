/*									tab:4
 * "Copyright (c) 2005 Stanford University. All rights reserved.
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
 *
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
 * Copyright (c) 2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */

/**
 * Interface for reading and writing CC2420 RXFIFO/TXFIFO memory using
 * the corresponding registers.
 *
 * @author Philip Levis
 * @author Joe Polastre
 * @date   September 7 2005
 */

interface CC2420Fifo {
  /**
   * Read from the RX FIFO queue.  Will read bytes from the queue
   * until the length is reached (determined by the first byte read).
   * The readRxFifoDone() event is signaled when all bytes have been
   * read or the end of the packet has been reached.
   *
   * @param data The data buffer.
   * @param length Number of bytes to read into the buffer.
   *
   * @return SUCCESS if the bus is free to read from the FIFO
   */
  async command error_t readRxFifo(uint8_t* data, uint8_t length);

  /**
   * Writes a series of bytes to the transmit FIFO. The
   * writeTxFifoDone() evented is signaled when all bytes have been
   * written.
   *
   * @param data The data buffer.
   * @param length Number of bytes in buffer to be written.
   *
   * @return SUCCESS if the bus is free to write to the FIFO
   */
  async command error_t writeTxFifo(uint8_t *data, uint8_t length);


  /**
   * Notification that the read request has completed. If <tt>err</tt>
   * is not SUCCESS, then length is always 0.
   *
   * @param data   The buffer the bytes were read into.
   * @param length The number of bytes actually read from the FIFO.
   * @param err    Whether an error occured in the read.
   *
   */
  async event void readRxFifoDone(uint8_t *data, uint8_t length, error_t err);

  /**
   * Notification that the bytes have been written to the FIFO
   * and if the write was successful. If <tt>err</tt> is not
   * SUCCESS, then length is always 0.
   *
   * @param data   The buffer the bytes were written from.
   * @param length The number of bytes written.
   * @param err    Whether an error occured in the write.
   *
   */
  async event void writeTxFifoDone(uint8_t *data, uint8_t length, error_t err);
}
