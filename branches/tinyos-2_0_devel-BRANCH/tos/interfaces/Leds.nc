// $Id: Leds.nc,v 1.1.2.2 2005-03-16 08:14:05 jpolastre Exp $

/*									tab:4
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
 * Interface for controlling the LEDs.
 *
 * @author Joe Polastre
 */

interface Leds {

  /**
   * Turn the first LED on
   */
  async command void led1On();

  /**
   * Turn the first LED off
   */
  async command void led1Off();

  /**
   * Toggle the first LED off
   */
  async command void led1Toggle();

  /**
   * Turn the second LED on
   */
  async command void led2On();

  /**
   * Turn the second LED off
   */
  async command void led2Off();

  /**
   * Toggle the second LED
   */
  async command void led2Toggle();

  /**
   * Turn the third LED on
   */
  async command void led3On();

  /**
   * Turn the third LED off
   */
  async command void led3Off();

  /**
   * Toggle the third LED
   */
  async command void led3Toggle();

  /**
   * Deprecated: Turn red on
   */
  async command error_t redOn();

  /**
   * Deprecated: Turn the red LED off.
   */
  async command error_t redOff();

  /**
   * Deprecated: Toggle the red LED. If it was on, turn it off. If it was off,
   * turn it on.
   */
  async command error_t redToggle();

  /**
   * Deprecated: Turn the green LED on.
   */
  async command error_t greenOn();

  /**
   * Deprecated: Turn the green LED off.
   */
  async command error_t greenOff();

  /**
   * Deprecated: 
   * Toggle the green LED. If it was on, turn it off. If it was off,
   * turn it on.
   */
  async command error_t greenToggle();

  /**
   * Deprecated: Turn the yellow LED on.
   */
  async command error_t yellowOn();

  /**
   * Deprecated: Turn the yellow LED off.
   */
  async command error_t yellowOff();

  /**
   * Deprecated: 
   * Toggle the yellow LED. If it was on, turn it off. If it was off,
   * turn it on.
   */
  async command error_t yellowToggle();
  
  /**
   * Get current Leds information
   *
   * @return A uint8_t typed value representing Leds status
   *
   */
   async command uint8_t get();

  /**
   * Set Leds to a specified value
   *
   * @param value ranging from 0 to 7 inclusive
   *
   * @return SUCCESS Always
   *
   */
   async command error_t set(uint8_t value);
}
