//$Id: MSP430InterruptPort2C.nc,v 1.1.2.1 2005-03-15 23:26:48 jpolastre Exp $

/* "Copyright (c) 2000-2005 The Regents of the University of California.  
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
configuration MSP430InterruptPort2C
{
#ifdef __msp430_have_port2
  provides interface MSP430Interrupt as Port20;
  provides interface MSP430Interrupt as Port21;
  provides interface MSP430Interrupt as Port22;
  provides interface MSP430Interrupt as Port23;
  provides interface MSP430Interrupt as Port24;
  provides interface MSP430Interrupt as Port25;
  provides interface MSP430Interrupt as Port26;
  provides interface MSP430Interrupt as Port27;
#endif
}
implementation
{
  components MSP430InterruptPort2M;

#ifdef __msp430_have_port2
  Port20 = MSP430InterruptM.Port20;
  Port21 = MSP430InterruptM.Port21;
  Port22 = MSP430InterruptM.Port22;
  Port23 = MSP430InterruptM.Port23;
  Port24 = MSP430InterruptM.Port24;
  Port25 = MSP430InterruptM.Port25;
  Port26 = MSP430InterruptM.Port26;
  Port27 = MSP430InterruptM.Port27;
#endif
}
