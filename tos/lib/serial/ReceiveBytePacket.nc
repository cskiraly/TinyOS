//$Id: ReceiveBytePacket.nc,v 1.1.2.4 2005-08-07 21:56:15 scipio Exp $

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
 * This is the data interface that a serial protocol (F) provides and
 * a serial dispatcher (D) uses. D assumes this pattern of calls: (
 * start+ data* end+)*
 *
 * It ignores any signals that do not fit this pattern. If it receives
 * the following sequence
 *
 *   start data data start data data end

 * it ignores the second start and reads in a four byte packet. 
 *
 * @author Philip Levis
 * @author Ben Greenstein
 * @date August 7 2005
 *
 */

interface ReceiveBytePacket {

  
  async event error_t startPacket();

  /* This implementation must be able to handle nested interrupts. As
   * the data sharing is one way, that's not a big deal (atomically
   * put it in). */
  async event void byteReceived(uint8_t b);
  async event void endPacket(error_t result);
}

