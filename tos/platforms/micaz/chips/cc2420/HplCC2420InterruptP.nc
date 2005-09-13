/*									tab:4
 * "Copyright (c) 2005 Stanford University. All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and
 * its documentation for any purpose, without fee, and without written
 * agreement is hereby granted, provided that the above copyright
 * notice, the following two paragraphs and the author appear in all
 * copies of this software.
 * 
 * IN NO EVENT SHALL STANFORD UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES
 * ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN
 * IF STANFORD UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
 * DAMAGE.
 * 
 * STANFORD UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE
 * PROVIDED HEREUNDER IS ON AN "AS IS" BASIS, AND STANFORD UNIVERSITY
 * HAS NO OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES,
 * ENHANCEMENTS, OR MODIFICATIONS."
 *
 * "Copyright (c) 2000-2003 The Regents of the University  of California.  
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
 *
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */

/**
 * MicaZ implementation of the CC2420 interrupts. FIFOP is a real
 * interrupt, while CCA and FIFO are emulated through timer polling.
 * <pre>
 *  $Id: HplCC2420InterruptP.nc,v 1.1.2.1 2005-09-13 20:24:49 scipio Exp $
 * <pre>
 *
 * @author Philip Levis
 * @author Matt Miller
 * @date   September 11 2005
 */

includes Timer;

module HplCC2420InterruptP {
  provides {
    interface Interrupt as FIFOP;
    interface Interrupt as FIFO;
    interface Interrupt as CCA;
    interface Capture as SFD;
  }
  uses {
    interface HplInterrupt as SubFIFOP;
    interface GeneralIO as CC_FIFO;
    interface GeneralIO as CC_CCA;
    interface HplCapture<uint16_t> as SFDCapture;
    interface Timer<TMilli> as FIFOTimer;
    interface Timer<TMilli> as CCATimer;
  }
}
implementation {
  norace uint8_t FIFOWaitForState;
  norace uint8_t FIFOLastState;
  
  norace uint8_t CCAWaitForState;
  norace uint8_t CCALastState;
  bool ccaTimerDisabled = FALSE;
  // Add stdcontrol.init/.start to setup TimerCapture timebase

  // ************* FIFOP Interrupt handlers and dispatch *************
  
  /*********************************************************
  * 
  *  enable CC2420 fifop interrupt (on INT6 pin of ATMega128)
  CC2420 is configured for FIFOP interrupt on RXFIFO > Thresh
  where thresh is programmed in CC2420Const.h CP_IOCFGO reg. 
  Threshold is 127 asof 15apr04 (AlmostFull)
  FIFOP is asserted as long as RXFIFO>Threshold
  FIFOP is active LOW
  Type	ISCn1 ISCn0
  Hi-Lo	1	0
  Lo-Hi	1	1
  ********************************************************/
  async command error_t FIFOP.startWait(bool low_to_high) {
    call SubFIFOP.edge(low_to_high);
    call SubFIFOP.enable();
    return SUCCESS;
  }
  
  /**
   * disables FIFOP interrupts
   */
  async command error_t FIFOP.disable() {
    call SubFIFOP.disable();
    return SUCCESS;
  }

  async event void SubFIFOP.fired() {
    signal FIFOP.fired();
  }
  
 default async event void FIFOP.fired() {}
  
  // ************* FIFO Interrupt handlers and dispatch *************
  
  /**
   * enable an edge interrupt on the FIFO pin
    not INTERRUPT enabled on MICAz
    Best we can do is poll periodically and monitor line level changes
   */
  async command error_t FIFO.startWait(bool low_to_high) {
    
    atomic FIFOWaitForState = low_to_high; //save the state we are waiting for
    FIFOLastState = call CC_FIFO.get(); //get current state
    call FIFOTimer.startOneShotNow(1); //wait 1msec
    return SUCCESS;
   } //.startWait


  /**
   * TImer Event fired so now check  FIFO pin level
   */
  event void FIFOTimer.fired() {
    uint8_t FIFOState;
    //check FIFO state
    FIFOState = call CC_FIFO.get(); //get current state
    if ((FIFOLastState != FIFOWaitForState) && (FIFOState==FIFOWaitForState)) {
      //here if found an edge
      signal FIFO.fired();
    }//if FIFO Pin
    //restart timer and try again
    FIFOLastState = FIFOState;
    call FIFOTimer.startOneShotNow(1); //wait 1msec
  }//FIFOTimer.fired


  /**
   * disables FIFO interrupts
   */
  async command error_t FIFO.disable() {
    call FIFOTimer.stop();
    return SUCCESS;
  }

 default async event void FIFO.fired() {}

  // ************* CCA Interrupt handlers and dispatch *************
  
  /**
   * enable an edge interrupt on the CCA pin
   NOT an interrupt in MICAz. Implement as a timer polled pin monitor
   */

  task void CCATask() {
    atomic {
      if (!ccaTimerDisabled) 
	call CCATimer.startOneShotNow(100);
    }
  }
  
  async command error_t CCA.startWait(bool low_to_high) {
    atomic CCAWaitForState = low_to_high; //save the state we are waiting for
    atomic ccaTimerDisabled = FALSE;
    CCALastState = call CC_CCA.get(); //get current state
    post CCATask();
    return SUCCESS;
  }

  /**
   * disables CCA interrupts
   */
  void task stopTask() {
    atomic{
      if (ccaTimerDisabled) {
	call CCATimer.stop();
      }
    }
  }
  async command error_t CCA.disable() {
    atomic ccaTimerDisabled = TRUE;
    post stopTask();
    return SUCCESS;
  }

  /**
   * TImer Event fired so now check for CCA	level
   */
  event void CCATimer.fired() {
    uint8_t CCAState;
    atomic {
      if (ccaTimerDisabled) {
	return;
      }
    }
    //check CCA state
    CCAState = call CC_CCA.get(); //get current state
    //here if waiting for an edge
    if ((CCALastState != CCAWaitForState) && (CCAState==CCAWaitForState)) {
      signal CCA.fired();
    }//if CCA Pin is correct and edge found
    //restart timer and try again
    CCALastState = CCAState;
    post CCATask();
    return;
  }//CCATimer.fired

 default async event void CCA.fired() {}

  // ************* SFD Interrupt handlers and dispatch *************
 /**
 SFD.enableCapture
 Configure Atmega128 TIMER1 to capture edge input of SFD signal.
 This will cause an interrupt and save TIMER1 count.
 Timer1 Timebase is set by stdControl.start - see SFDCapture Component Module
 *******************************************************************/
  async command error_t SFD.enableCapture(bool low_to_high) {
    atomic {
      //TOSH_SEL_CC_SFD_MODFUNC();
      call SFDCapture.stop(); //this also clears any capture interrupt
      call SFDCapture.setEdge(low_to_high);
      call SFDCapture.reset();
      call SFDCapture.start();
    }
    return SUCCESS;
  }

  async command void SFD.disable() {
    call SFDCapture.stop();
  }
/** .captured
Handle signal from SFDCapture interface indicating an external event has
been timestamped. 
Signal client with time and disable capture timer if nolonger needed.
*****************************************************************************/
  async event void SFDCapture.captured(uint16_t time) {
    call SFDCapture.reset();
    signal SFD.captured(time);     //signal client
  }//captured

 default async event void SFD.captured(uint16_t val) {}

} //Module HPLCC2420InterruptM
  
