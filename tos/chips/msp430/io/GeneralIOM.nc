//$Id: GeneralIOM.nc,v 1.1.2.1 2005-04-21 22:09:00 jpolastre Exp $

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

generic module GeneralIOM() {
  provides interface GeneralIO;
  uses interface MSP430GeneralIO;
}
implementation {

  async command void GeneralIO.set() { call MSP430GeneralIO.set(); }
  async command void GeneralIO.clr() { call MSP430GeneralIO.clr(); }
  async command void GeneralIO.toggle() { call MSP430GeneralIO.toggle(); }
  async command bool GeneralIO.get() { return call MSP430GeneralIO.get(); }
  async command void GeneralIO.makeInput() { call MSP430GeneralIO.makeInput(); }
  async command void GeneralIO.makeOutput() { call MSP430GeneralIO.makeOutput(); }

}