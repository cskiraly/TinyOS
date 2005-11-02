/**
 * Accessor methods used by a serial dispatcher to communicate with various
 * message_t link formats over a serial port.
 *
 * @author Philip Levis
 * @author Ben Greenstein
 * @date August 7 2005
 */

interface SerialPacketInfo {
  /**
   * Returns the offset into a message where the header information begins.
   */
  async command uint8_t offset();
  /**
   * Returns the size of the datalink packet embedded in the message_t, in bytes. 
   * This is the sum of the payload (upperLen) and the size of the link header.
   */
  async command uint8_t dataLinkLength(message_t* msg, uint8_t upperLen);
  /**
   * Retuns the size of the payload (in bytes) given the size of the datalink
   * packet (dataLinkLen) embedded in the message_t.
   */
  async command uint8_t upperLength(message_t* msg, uint8_t dataLinkLen);
}
