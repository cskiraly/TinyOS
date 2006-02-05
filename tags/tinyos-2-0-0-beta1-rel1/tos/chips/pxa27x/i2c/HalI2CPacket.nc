// $Id: HalI2CPacket.nc,v 1.1.2.1 2006-02-01 23:54:24 philipb Exp $
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
 *
 * @author Joe Polastre, Phil Buonadonna, David Gay
 * Revision:  $Revision: 1.1.2.1 $
 */

interface I2CPacket {
  /**
   * Perform an I2C read operation
   *
   * @param addr The slave device address
   * @param length Length, in bytes, to be read
   * @param data A point to a data buffer to read into
   * @param flags Flags that may be logical ORed and defined by:
   * <table border=0><tr><td><code>STOP_FLAG</code></td>
   * <td><code>0x01</code></td>
   * <td>The stop/end command is sent at the end of the packet if set</td></tr>
   * <tr><td><code>ACK_FLAG</code></td>
   * <td><code>0x02</code></td>
   * <td>The master acks every byte except for the last received if set</td></tr>
   * <tr><td><code>ACK_END_FLAG</code></td>
   * <td><code>0x04</code></td>
   * <td>The master acks after the last byte read if set</td></tr>
   * <tr><td><code>ADDR_8BITS_FLAG</code></td>
   * <td><code>0x80</code></td>
   * <td>The slave address is a full eight bits, not seven and a read flag.</td></tr>
   * </table>
   *
   * @return SUCCESS if bus available and request accepted. 
   */
  async command result_t readPacket(uint16_t _addr, uint8_t _length, uint8_t* _data, i2c_flags_t flags);

  /**
   * Perform an I2C write or STOP/ABORT operation. 
   *
   * @param addr The slave device address
   * @param length Length, in bytes, to be written. Set to zero to issue a STOP/ABORT.
   * @param data A pointer to a data buffer to write from
   * @param flags Flags that may be logical ORed and defined by:
   * <table border=0><tr><td><code>STOP_FLAG</code></td>
   * <td><code>0x01</code></td>
   * <td>The stop/end command is sent at the end of the packet if set</td></tr>
   * <tr><td><code>ADDR_8BITS_FLAG</code></td>
   * <td><code>0x80</code></td>
   * <td>The slave address is a full eight bits, not seven and a read flag.</td></tr>
   * </table>
   *
   * @return SUCCESS if bus available and request accepted.
   */
  async command result_t writePacket(uint16_t _addr, uint8_t _length, uint8_t* _data, i2c_flags_t flags);

  /**
   * Notification that the read operation has completed
   *
   * @param addr The slave device address
   * @param length Length, in bytes, read
   * @param data Pointer to the received data buffer
   * @param success SUCCESS if transfer completed without error.
   */
  async event void readPacketDone(uint16_t addr, uint8_t length, uint8_t* data, result_t success);

  /**
   * Notification that the write operation has completed
   *
   * @param addr The slave device address
   * @param length Length, in bytes, written
   * @param data Pointer to the data buffer written
   * @param success SUCCESS if transfer completed without error.
   */
  async event void writePacketDone(uint16_t addr, uint8_t length, uint8_t* data, result_t success);
}
