// $Id: FlashWPM.nc,v 1.1.2.2 2005-06-07 20:05:35 jwhui Exp $

/*									tab:2
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

/*
 * @author: Jonathan Hui <jwhui@cs.berkeley.edu>
 */

module FlashWPM {
  provides {
    interface FlashWP;
    interface StdControl;
  }
  uses {
    interface HALSTM25P;
  }
}

implementation {

  uint8_t state;

  enum {
    S_IDLE = 0xff,
    S_CLR = 0x00,
    S_SET = 0x84,
  };

  command result_t StdControl.init() {
    state = S_IDLE;
    return SUCCESS;
  }

  command result_t StdControl.start() { return SUCCESS; }
  command result_t StdControl.stop() { return SUCCESS; }

  result_t newRequest(uint8_t newState) {

    result_t result;

    if (state != S_IDLE)
      return FAIL;
    
    result = call HALSTM25P.writeSR(newState);

    if (result == SUCCESS)
      state = newState;
      
    return result;

  }

  command result_t FlashWP.clrWP() {
    return newRequest(S_CLR);
  }

  command result_t FlashWP.setWP() {
    return newRequest(S_SET);
  }
  
  event void HALSTM25P.writeSRDone() {
    uint8_t tmpState = state;
    state = S_IDLE;
    switch(tmpState) {
    case S_CLR: signal FlashWP.clrWPDone(); break;
    case S_SET: signal FlashWP.setWPDone(); break;
    }
  }

  event void HALSTM25P.pageProgramDone() {}
  event void HALSTM25P.sectorEraseDone() {}
  event void HALSTM25P.bulkEraseDone() {}

}
