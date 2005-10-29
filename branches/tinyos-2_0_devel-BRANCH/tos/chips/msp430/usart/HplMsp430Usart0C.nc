/**                                                                      tab:2
 * "Copyright (c) 2000-2005 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and
 * its documentation for any purpose, without fee, and without written
 * agreement is hereby granted, provided that the above copyright
 * notice, the following two paragraphs and the author appear in all
 * copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY
 * PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL
 * DAMAGES ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS
 * DOCUMENTATION, EVEN IF THE UNIVERSITY OF CALIFORNIA HAS BEEN
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE
 * PROVIDED HEREUNDER IS ON AN "AS IS" BASIS, AND THE UNIVERSITY OF
 * CALIFORNIA HAS NO OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT,
 * UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 * $ Revision: $
 * $ Date: $
 *
 * @author Joe Polastre
 */

configuration HplMsp430Usart0C {
  provides interface Init;
  provides interface Resource[ uint8_t id ];
  provides interface ResourceUser;
  provides interface HplMsp430Usart;
}

implementation {

  components HplMsp430Usart0P as HplUsartP;
  components MSP430GeneralIOC as GIO;
  components new FcfsArbiterC( "Msp430Usart0.Resource" ) as Arbiter;

  Init = Arbiter;
  Resource = Arbiter;
  ResourceUser = Arbiter;
  HplMsp430Usart = HplUsartP;

  HplUsartP.SIMO -> GIO.SIMO0;
  HplUsartP.SOMI -> GIO.SOMI0;
  HplUsartP.UCLK -> GIO.UCLK0;
  HplUsartP.URXD -> GIO.URXD0;
  HplUsartP.UTXD -> GIO.UTXD0;

}
