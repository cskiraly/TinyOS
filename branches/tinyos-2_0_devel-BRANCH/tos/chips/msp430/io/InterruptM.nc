//$Id: InterruptM.nc,v 1.1.2.2 2005-04-21 23:10:00 jpolastre Exp $

/* "Copyright (c) 2000-2003 The Regents of the University of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement
 * is hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY
 * OF CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 */

/**
 * @author Joe Polastre
 */

generic module InterruptM() {
  provides interface Interrupt;
  uses interface MSP430Interrupt;
}
implementation {
  /**
   * enable an edge interrupt on the Interrupt pin
   */
  async command error_t Interrupt.startWait(bool low_to_high) {
    atomic {
      call MSP430Interrupt.disable();
      call MSP430Interrupt.clear();
      call MSP430Interrupt.edge(low_to_high);
      call MSP430Interrupt.enable();
    }
    return SUCCESS;
  }

  /**
   * disables Interrupt interrupts
   */
  async command error_t Interrupt.disable() {
    atomic {
      call MSP430Interrupt.disable();
      call MSP430Interrupt.clear();
    }
    return SUCCESS;
  }

  /**
   * Event fired by lower level interrupt dispatch for Interrupt
   */
  async event void MSP430Interrupt.fired() {
    call MSP430Interrupt.clear();
    signal Interrupt.fired();
  }

  default async event error_t Interrupt.fired() { return FAIL; }
}