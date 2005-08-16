//$Id: SendBytePacket.nc,v 1.1.2.8 2005-08-16 21:27:04 bengreenstein Exp $

/* "Copyright (c) 2000-2005 The Regents of the University of California.  
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
 * This is an interface that a serial framing protocol provides and a serial
 * dispatcher uses. The call sequence should be as follows:
 * The dispatcher should call startSend, specifying the first byte to
 * send. The framing protocol can then signal as many nextBytes as it
 * wants/needs, to spool in the bytes. It continues to do so until it receives
 * a sendComplete call, which will almost certainly happen within a nextByte
 * signal (i.e., re-entrant to the framing protocol).

 * This allows the framing protocol to buffer as many bytes as it needs to to meet
 * timing requirements, jitter, etc. 
 *
 * @author Philip Levis
 * @author Ben Greenstein
 * @date August 7 2005
 *
 */


interface SendBytePacket {
  /**
   * The dispatcher may initiate a serial transmission by calling this function
   * and passing the first byte to be transmitted. The framer will either return
   * SUCCESS if it has the resources available to transmit a frame or EBUSY if not.
   */
  async command error_t startSend(uint8_t first_byte);

  /**
   * The dispatcher must indicate when the end-of-packet has been reached and does
   * so by calling completeSend. The function may be called from within the
   * implementation of a nextByte event.
   */
  async command error_t completeSend();

  /** The semantics on this are a bit tricky, as it should be able to
   * handle nested interrupts (self-preemption) if the signalling
   * component has a buffer. Signals to this event
   * are considered atomic. This means that the underlying component MUST
   * have updated its state so that if it is preempted then bytes will
   * be put in the right place (store variables on the stack, etc).
   */
  
  /**
   * Used by the framer to request the next byte to transmit. The framer may
   * allocate a buffer to pre-spool some or all of a packet; or it may request
   * and transmit a byte at a time.
   */
  async event uint8_t nextByte();

  /**
   * The framer signals sendCompleted to indicate that it is done transmitting a
   * packet on the dispatcher's behalf. A non-SUCCESS error_t code indicates that
   * there was a problem in transmission.
   */
  async event void sendCompleted(error_t error);
}



