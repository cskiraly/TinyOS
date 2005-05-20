/*									tab:4
 * "Copyright (c) 2000-2002 The Regents of the University  of California.  
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
/*
 * Authors:		Joe Polastre
 * Date last modified:  $Revision: 1.1.2.3 $
 *
 * Interface for controlling the radio in a hardware independent manner
 */

/**
 * Radio control interface
 */
interface RadioControl
{
  /**
   * Set the TinyOS RF channel for this device.
   *
   * @param channel Desired TinyOS RF channel.  Must be between
   *                zero and GetMaxChannels() - 1.
   *
   * @return SUCCESS if the RF channel was successfully changed
   */
  command error_t SetRFChannel(uint8_t channel);

  /**
   * Get the TinyOS RF channel for this device.
   * 
   * @return TinyOS non-overlapping RF channel currently in use
   */
  command uint8_t GetRFChannel();

  /**
   * Get the maximum number of RF channels available for this device
   *
   * @return n, where channels 0 to n-1 are non-overlapping channels
   */
  command uint8_t GetMaxChannels();

  /**
   * Set the transmit RF power value.  
   * Valid values are 0 through 255 corresponding to the relative
   * radio power.  0 is minimum power, 255 is maximum power.
   *
   * @param power A power index between 0 and 255
   * 
   * @result SUCCESS if the radio power was adequately set.
   *
   */
  command error_t SetRFPower(uint8_t power);	

  /**
   * Get the present RF power index.
   *
   * @result The power index value between 0 and 255
   */
  command uint8_t GetRFPower();

  /**
   * Convert an RFPower (0-255) relative setting to the actual
   * DB setting
   *
   * @param power A power index between 0 and 255
   *
   * @result The corresponding output dBm of the input power level
   */
  command int8_t RFtoDB(uint8_t power);

  /**
   * Convert a dBm value to a relative RFPower value.
   *
   * If the radio cannot support the requested dBm value,
   * it will return
   * 
   * @param dbm dBm output power to convert to relative RF value
   *
   * @result The corresponding RF power level (0-255)
   */
  command uint8_t DBtoRF(int8_t dbm);

  /**
   * Read the value for the time to send a bit over the radio
   *
   * @return bit time in microseconds
   */
  command uint16_t getTimeBit();

  /**
   * Read the value for the time to send a byte over the radio
   *
   * @return byte time in microseconds
   */
  command uint16_t getTimeByte();

  /**
   * Read the value for the time elapsed in one radio symbol period
   *
   * @return symbol period in microseconds
   */
  command uint16_t getTimeSymbol();

}
