//$Id: SendBytePacket.nc,v 1.1.2.7 2005-08-08 02:52:22 scipio Exp $

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
 * This is an interface that a serial protocol (F) provides and a serial
 * dispatcher (D) uses.
 * Call sequence is this:
 * D calls startSend, specifying the first byte to send.
 * F can then signal as many nextBytes as it wants/needs, to spool in
 *   the bytes. It continues to do so until it receives a call to
 *   sendComplete, which will almost certainly happen within     
 *   a nextByte signal (i.e., re-entrant to F).
 *
 * This allows F to buffer as many bytes as it needs to to meet
 * timing requirements, jitter, etc. The one thing to be
 * careful of is how indices into buffers are managed, in the
 * case of re-entrant interrupts.
 *
 * @author Philip Levis
 * @author Ben Greenstein
 * @date August 7 2005
 *
 */


interface SendBytePacket {
  async command error_t startSend(uint8_t first_byte);
  async command error_t completeSend();

  /** The semantics on this are a bit tricky, as it should be able to
   * handle nested interrupts (self-preemption) if the signalling
   * component has a buffer. Signals to this event
   * are considered atomic. This means that the underlying component MUST
   * have updated its state so that if it is preempted then bytes will
   * be put in the right place (store variables on the stack, etc).
   */
  
  async event uint8_t nextByte();

  async event void sendCompleted(error_t error);
}



