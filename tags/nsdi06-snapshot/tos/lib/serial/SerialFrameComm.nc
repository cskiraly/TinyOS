//$Id: SerialFrameComm.nc,v 1.1.2.5 2005-08-16 21:27:04 bengreenstein Exp $

/* "Copyright (c) 2005 The Regents of the University of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement
 * is hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY
 * OF CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 */

/**
 *
 * This interface sits between a serial byte encoding component and a
 * framing/packetizing component. It is to be used with framing protocols
 * that place delimiters between frames. This interface separates the tasks
 * of interpreting and coding delimiters and escape bytes from the rest of
 * the wire protocol.
 *
 * @author Philip Levis
 * @author Ben Greenstein
 * @date   August 7 2005
 */
   
interface SerialFrameComm {
  /**
   * Used by the upper layer to request that an interframe delimiter
   * be sent. The lower layer is responsible for the determining the
   * actual byte(s) that must be sent to delimit the frame.
   */
  async command error_t putDelimiter();

  /**
   *  Request that a byte of data be sent over serial. 
   */
  async command error_t putData(uint8_t data);

  /**
   * Requests that any underlying state associated with send-side frame
   * delimiting or escaping be reset. Used to initialize the lower
   * layer's send path and/or cancel a frame mid-transmission.
   */
  async command void resetSend();

  /**
   * Requests that any underlying state associated with receive-side
   * frame or escaping be reset. Used to initialize the lower layer's
   * receive path and/or cancel a frame mid-reception when sync is lost.
   */
  async command void resetReceive();

  /**
   * Signals the upper layer that an inter-frame delimiter has been 
   * received from the serial connection.
   */
  async event void delimiterReceived();

  /**
   * Signals the upper layer that a byte of data has been received from
   * the serial connection. It passes this byte as a function parameter.
   */
  async event void dataReceived(uint8_t data);

  /**
   * Split-phase event to signal when the lower layer has finished writing
   * the last request (either putDelimiter or putData) to serial.
   */
  async event void putDone(); 
}