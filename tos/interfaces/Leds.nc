// $Id: Leds.nc,v 1.1.2.3 2005-03-19 20:59:16 scipio Exp $

/*									tab:4
 * "Copyright (c) 2005-2005 The Regents of the University  of California.  
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
 * Commands for controlling three LEDs. A platform can provide this
 * interface if it has more than or fewer than three LEDs. In the
 * former case, these commands refer to the first three LEDs. In the
 * latter case, some of the commands are null operations, and the set
 * of non-null operations must be contiguous and start at Led1. That
 * is, on platforms with 2 LEDs, LED 3's commands are null operations,
 * while on platforms with 1 LED, LED 2 and LED 3's commands are null
 * opertations.
 *
 * @author Joe Polastre
 * @author Philip Levis
 */

interface Leds {

  /**
   * Turn on LED 1. The color of this LED depends on the platform.
   */
  async command void led1On();

  /**
   * Turn off LED 1. The color of this LED depends on the platform.
   */
  async command void led1Off();

  /**
   * Toggle LED 1; if it was off, turn it on, if was on, turn it off.
   * The color of this LED depends on the platform.
   */
  async command void led1Toggle();

  /**
   * Turn on LED 2. The color of this LED depends on the platform.
   */
  async command void led2On();

  /**
   * Turn off LED 2. The color of this LED depends on the platform.
   */
  async command void led2Off();

   /**
   * Toggle LED 2; if it was off, turn it on, if was on, turn it off.
   * The color of this LED depends on the platform.
   */
  async command void led2Toggle();

 
  /**
   * Turn on LED 3. The color of this LED depends on the platform.
   */
  async command void led3On();

  /**
   * Turn off LED 3. The color of this LED depends on the platform.
   */
  async command void led3Off();

   /**
   * Toggle LED 3; if it was off, turn it on, if was on, turn it off.
   * The color of this LED depends on the platform.
   */
  async command void led3Toggle();

}
