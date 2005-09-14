// $Id: Capture.nc,v 1.1.2.3 2005-09-14 01:07:04 scipio Exp $
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
 * Interface for microcontroller-independent 32kHz timer capture events.
 * 
 * @author Philip Levis
 * @author Joe Polastre
 * @date   September 9 2005
 *
 */

includes TinyError;

interface Capture {

  /** 
   * Enable an edge based timer capture event.
   *
   * @param low_to_high TRUE if the edge capture should occur on
   *        a low to high transition, FALSE for high to low.
   *
   * @return Whether the timer capture has been enabled.
   */
  async command error_t enableCapture(bool low_to_high);

  /**
   * Fired when an edge interrupt occurs.
   *
   * @param val The value of the 32kHz timer.
   *
   */
  async event void captured(uint16_t time);

  /**
   * Disable further captures.
   */ 
  async command void disable();
}
