// $Id: Capture.nc,v 1.1.2.1 2005-03-14 01:58:53 jpolastre Exp $
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
 * @author Joe Polastre
 * Revision:  $Revision: 1.1.2.1 $
 *
 * Interface for providing Timing and Capture events in a microcontroller
 * independent manner.
 */

interface Capture {

  /** 
   * Enable an edge based timer capture
   *
   * @param low_to_high TRUE if the edge capture should occur on
   *        a low to high transition, FALSE for high to low.
   *
   * @return SUCCESS if the timer capture has been enabled
   */
  async command result_t enableCapture(bool low_to_high);

  /**
   * Fired when an edge interrupt occurs.
   *
   * @param val the raw value of the timer captured at 32kHz resolution
   *
   * @return SUCCESS to keep the interrupt enabled, FAIL to disable
   *         the interrupt
   */
  async event result_t captured(uint32_t time);

  /**
   * Diables a capture interrupt
   * 
   * @return SUCCESS if the interrupt has been disabled
   */ 
  async command result_t disable();
}
