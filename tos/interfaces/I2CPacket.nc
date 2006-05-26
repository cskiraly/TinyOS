// $Id: I2CPacket.nc,v 1.1.2.4 2006-05-26 00:39:55 philipb Exp $
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
 * completed.  The I2CPacket interface supports master-mode communication
 * and provides for multiple repeated STARTs and multiple reads/writes 
 * within the same START transaction. 
 *
 * @author Joe Polastre
 * @author Phil Buonadonna <pbuonadonna@archrock.com>
 * Revision:  $Revision: 1.1.2.4 $
 */

interface I2CPacket {
  /**
   * Perform an I2C read operation
   *
   * @param addr The slave device address
   * @param length Length, in bytes, to be read
   * @param data A point to a data buffer to read into
   * @param flags Flags that may be logical ORed and defined by:
   *    START_FLAG   - The START condition is transmitted at the beginning 
   *                   of the packet if set.
   *    STOP_FLAG    - The STOP condition is transmitted at the end of the 
   *                   packet if set.
   *    ACK_END_FLAG - ACK the last byte if set. Otherwise NACK last byte. This
   *                   flag cannot be used with the STOP_FLAG.
   *	ADDR10_FLAG  - Slave device address is 10-bit if set. 7-bit if not set.
   *
   * @return SUCCESS if bus available and request accepted. 
   */
  async command error_t read(uint16_t addr, uint8_t length, uint8_t* data, i2c_flags_t flags);

  /**
   * Perform an I2C write operation
   *
   * @param addr The slave device address
   * @param length Length, in bytes, to be read
   * @param data A point to a data buffer to read into
   * @param flags Flags that may be logical ORed and defined by:
   *    START_FLAG   - The START condition is transmitted at the beginning 
   *                   of the packet if set.
   *    STOP_FLAG    - The STOP condition is transmitted at the end of the 
   *                   packet if set.
   *	ADDR10_FLAG  - Slave device address is 10-bit if set. 7-bit if not set.
   *
   * @return SUCCESS if bus available and request accepted. 
   */
  async command error_t write(uint16_t addr, uint8_t length, uint8_t* data, i2c_flags_t flags);

  /**
   * Notification that the read operation has completed
   *
   * @param addr The slave device address
   * @param length Length, in bytes, read
   * @param data Pointer to the received data buffer
   * @param success SUCCESS if transfer completed without error.
   */
  async event void readDone(uint16_t addr, uint8_t length, uint8_t* data, error_t success);

  /**
   * Notification that the write operation has completed
   *
   * @param addr The slave device address
   * @param length Length, in bytes, written
   * @param data Pointer to the data buffer written
   * @param success SUCCESS if transfer completed without error.
   */
  async event void writeDone(uint16_t addr, uint8_t length, uint8_t* data, error_t success);
}
