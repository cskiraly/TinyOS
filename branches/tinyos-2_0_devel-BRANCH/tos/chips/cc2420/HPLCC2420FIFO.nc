// $Id: HPLCC2420FIFO.nc,v 1.1.2.3 2005-05-18 05:17:55 jpolastre Exp $
/*
 * "Copyright (c) 2000-2005 The Regents of the University  of California.
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
 */

/**
 * @author Joe Polastre
 * Revision:  $Revision: 1.1.2.3 $
 *
 * Interface for microcontroller-indepedent access to the FIFO buffers
 * inside the CC2420 transceiver.
 */

includes TinyError;

interface HPLCC2420FIFO {
  /**
   * Read from the RX FIFO queue.  Will read bytes from the queue
   * until the length is reached (determined by the first byte read).
   * RXFIFODone() is signalled when all bytes have been read or the
   * end of the packet has been reached.
   *
   * @param length number of bytes requested from the FIFO
   * @param data buffer bytes should be placed into
   *
   * @return SUCCESS if the bus is free to read from the FIFO
   */
  command error_t readRXFIFO(uint8_t length, uint8_t *data);

  /**
   * Writes a series of bytes to the transmit FIFO.
   *
   * @param length length of data to be written
   * @param data the first byte of data
   *
   * @return SUCCESS if the bus is free to write to the FIFO
   */
  command error_t writeTXFIFO(uint8_t length, uint8_t *data);

  /**
   * Notification that a byte from the RX FIFO has been received.
   *
   * @param length number of bytes actually read from the FIFO
   * @param data buffer the bytes were read into
   *
   * @return SUCCESS 
   */
  event error_t RXFIFODone(uint8_t length, uint8_t *data);

  /**
   * Notification that the bytes have been written to the FIFO
   * and if the write was successful.
   *
   * @param length number of bytes written to the fifo queue
   * @param data the buffer written to the fifo queue
   *
   * @return SUCCESS
   */
  event error_t TXFIFODone(uint8_t length, uint8_t *data);
}
