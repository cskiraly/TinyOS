// $Id: SPIPacket.nc,v 1.1.2.1 2005-02-25 03:04:42 jpolastre Exp $
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
 * SPI Packet/buffer interface for sending data over an SPI bus.
 * This interface provides a synchronous send command where an equal
 * transmit and receive buffer are provided to services using the SPI
 * bus.  A single byte may be transmitted or received over the bus using
 * this interface.  This interface is only for buffer based
 * transfers where the microcontroller is the master (clocking) device.
 *
 * The SPI bus must first be acquired using BusArbitration in order for
 * commands to be accepted by the SPIPacket interface.
 *
 * @author Joe Polastre
 * Revision:  $Revision: 1.1.2.1 $
 */
interface SPIPacket {

  /**
   * Send a message over the SPI bus.
   *
   * @param txbuffer A pointer to the buffer to send over the bus
   * @param rxbuffer A pointer to the buffer where received data should
   *                 be stored
   * @param length Length of the message.  Note that both the rxbuffer and
   *               txbuffer must be AT LEAST as long as the length provided
   *               in this command.
   *
   * @return SUCCESS if the request was accepted for transfer
   */
  command error_t send(uint8_t* txbuffer, uint8_t* rxbuffer, uint8_t length);
  /**
   * Notification that the send command has completed.
   *
   * @param txbuffer The buffer used for transmission
   * @param rxbuffer The buffer used for reception
   * @param length The request length of the transfer, but not necessarily
   *               the number of bytes that were actually transferred
   * @param success SUCCESS if the operation completed successfully, FAIL 
   *                otherwise
   */
  event void sendDone(uint8_t* txbuffer, uint8_t* rxbuffer, uint8_t length, error_t success);

}
