// $Id: SPIPacketAdvanced.nc,v 1.1.2.1 2005-02-25 03:04:42 jpolastre Exp $
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
 * This "expert" interface provides a send command that can reduce the 
 * amount of buffer space required by a service or component.  
 * This interface is only for buffer based
 * transfers where the microcontroller is the master (clocking) device.
 *
 * The SPI bus must first be acquired using BusArbitration in order for
 * commands to be accepted by the SPIPacket interface.
 *
 * @author Joe Polastre
 * Revision:  $Revision: 1.1.2.1 $
 */
interface SPIPacketAdvanced {

  /**
   * Send a message over the SPI bus. 
   *
   * Examples:
   *
   * send(txbuf, 0, length, rxbuf, 0, length, length)
   * is equivalent to call SPIPacket.send(txbuf, rxbuf, length)
   *
   * send(txbuf, 0, 2, rxbuf, 2, length, length)
   * will transmit bytes 0 and 1 from txbuf and then receive from
   * position 2 through length-1.  A zero value is transmitted for any
   * position where the txbuf is not specified (ie position 2 through
   * length-1)
   *
   * @param txbuffer A pointer to the buffer to send over the bus
   * @param txstart The position in the transfer where the first byte of
   *                txbuffer should be sent
   * @param txend The position in the transfer where there is no more
   *              tx data to send
   * @param rxbuffer A pointer to the buffer where received data should
   *                 be stored
   * @param rxstart The position in the transfer where the first byte of
   *                rxbuffer should be received
   * @param rxend The position in the transfer where there is no more
   *              rx data to receive
   * @param length Length of the message.  Note that both the rxbuffer and
   *               txbuffer must be AT LEAST as long as the length provided
   *               in this command.
   *
   * @return SUCCESS if the request was accepted for transfer
   */
  command error_t send(uint8_t* txbuffer, uint8_t txstart, uint8_t txend, uint8_t* rxbuffer, uint8_t rxstart, uint8_t rxend, uint8_t length);

  /**
   * Notification that the send command has completed.
   *
   * @param txbuffer The buffer used for transmission
   * @param txstart The position of the first sent byte
   * @param txend Position where txbuf is no longer in use
   * @param rxbuffer The buffer used for reception
   * @param rxstart The position of the first received byte
   * @param rxend Position where rxbuf is no longer in use
   * @param length The request length of the transfer, but not necessarily
   *               the number of bytes that were actually transferred
   * @param success SUCCESS if the operation completed successfully, FAIL 
   *                otherwise
   */
  event void sendDone(uint8_t* txbuffer, uint8_t txstart, uint8_t txend, uint8_t* rxbuffer, uint8_t rxstart, uint8_t rxend, uint8_t length, error_t success);

}
