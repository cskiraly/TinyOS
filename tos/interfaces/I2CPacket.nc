// $Id: I2CPacket.nc,v 1.1.2.1 2005-02-24 00:21:41 jpolastre Exp $
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
 * I2C Packet/buffer interface for sending data over the I2C bus.
 * The address, length, and buffer must be specified.  The I2C bus then
 * has control of that buffer and returns it when the operation has
 * completed.  The I2CPacket interface only supports master-mode communication
 * and single tranfers (a start and stop condition are transmitted for
 * every packet operation).
 *
 * @author Joe Polastre
 * Revision:  $Revision: 1.1.2.1 $
 */
interface I2CPacket {
  /**
   * Perform an I2C read operation
   */
  command result_t readPacket(uint16_t _addr, uint8_t _length, uint8_t* _data);
  /**
   * Perform an I2C write operation
   */
  command result_t writePacket(uint16_t _addr, uint8_t _length, uint8_t* _data);

  /**
   * Notification that the read operation has completed
   */
  event void readPacketDone(uint16_t addr, uint8_t length, uint8_t* data, result_t success);
  /**
   * Notification that the write operation has completed
   */
  event void writePacketDone(uint16_t addr, uint8_t length, uint8_t* data, result_t success);
}
