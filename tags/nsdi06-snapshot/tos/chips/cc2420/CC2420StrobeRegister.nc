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
 */

/**
 * Interface representing one of the CC2420 command strobe registers.
 * Writing to one of these registers enacts a command on the CC2420,
 * such as power-up, transmission, or clear a FIFO.
 *
 * @author Philip Levis
 * @date   August 28 2005
 */

includes CC2420Const;

interface CC2420StrobeRegister {

  /**
   * Send a command strobe to the register. The return value is the
   * CC2420 status register. Table 5 on page 27 of the CC2420
   * datasheet (v1.2) describes the contents of this register.
   * 
   * @return Status byte from the CC2420.
   */
  async command cc2420_so_status_t cmd();

  /**
   * Put a command strobe sequence into a buffer, for later
   * transmission over the SPI.
   *
   * @return The number of bytes written to the buffer (always 1 for
   * command strobes). If for some reason a command cannot be put
   * (e.g., this is not a valid strobe register) 0 is returned.
   */
  async command uint8_t putCmd(uint8_t* buffer);

  /**
   * The length of a command sequence (in bytes).
   *
   * @return 1 byte for valid strobes, 0 for invalid.
   */
  async command uint8_t opLen();
}
