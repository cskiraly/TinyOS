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

includes msp430baudrates;

generic module Msp430UartP() {

  provides interface Init;
  provides interface StdControl;
  provides interface SerialByteComm;
  
  uses interface HplMsp430Usart as HplUsart;
}

implementation {

  command error_t Init.init() {
    return SUCCESS;
  }

  command error_t StdControl.start() {
    call HplUsart.setModeUART();
    call HplUsart.setClockSource(SSEL_SMCLK);
    call HplUsart.setClockRate(UBR_SMCLK_57600, UMCTL_SMCLK_57600);

    call HplUsart.enableRxIntr();
    call HplUsart.enableTxIntr();
    return SUCCESS;
  }

  command error_t StdControl.stop() {
    call HplUsart.disableRxIntr();
    call HplUsart.disableTxIntr();

    call HplUsart.disableUART();
    return SUCCESS;
  }

  async command error_t SerialByteComm.put( uint8_t data ) {
    call HplUsart.tx( data );
    return SUCCESS;
  }

  async event void HplUsart.txDone() {
    signal SerialByteComm.putDone();
  }

  async event void HplUsart.rxDone( uint8_t data ) {
    signal SerialByteComm.get( data );
  }
}
