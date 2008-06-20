// $Id: Interrupt.nc,v 1.1.2.3 2005-05-18 19:02:16 jpolastre Exp $
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
 * Revision:  $Revision: 1.1.2.3 $
 *
 * Provides a microcontroller-independent presentation of interrupts
 */


interface Interrupt {

  /** 
   * Enable an edge based interrupt
   *
   * @param low_to_high TRUE if the edge interrupt should occur on
   *        a low to high transition, FALSE for high to low.
   *
   * @return SUCCESS if the interrupt has been enabled
   */
  async command error_t startWait(bool low_to_high);

  /**  
   * Diables an edge interrupt or capture interrupt
   * 
   * @return SUCCESS if the interrupt has been disabled
   */ 
  async command error_t disable();

  /**
   * Fired when an edge interrupt occurs.
   *
   * NOTE: Interrupts keep running until "disable()" is called
   */
  async event void fired();

}