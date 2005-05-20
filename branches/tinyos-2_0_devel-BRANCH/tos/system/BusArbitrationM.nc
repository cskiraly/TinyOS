/*									tab:4
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
 */

/**
 * Generic module for Bus Arbitration.  The module code is replicated
 * for each instance and provides users of the bus with a method for
 * obtaining access to that bus.
 *
 * @author Joe Polastre
 *
 * $Id: BusArbitrationM.nc,v 1.1.2.2 2005-05-20 20:46:26 jpolastre Exp $
 */
generic module BusArbitrationM(char busname[]) {
  provides {
    interface Init;
    interface BusArbitration[uint8_t id];
  }
}
implementation {

  uint8_t state;
  uint8_t busid;

  enum { BUS_IDLE = 0, BUS_BUSY };

  task void busReleased() {
    uint8_t i;
    uint8_t currentstate;
    // tell everyone the bus has been released
    for (i = 0; i < uniqueCount(busname); i++) {
      atomic currentstate = state;
      if (currentstate == BUS_IDLE) 
        signal BusArbitration.busFree[i]();
    }
  }
 
  command error_t Init.init() {
    state = BUS_IDLE;
    return SUCCESS;
  }

  async command error_t BusArbitration.getBus[uint8_t id]() {
    bool gotbus = FALSE;
    atomic {
      if (state == BUS_IDLE) {
        state = BUS_BUSY;
        gotbus = TRUE;
        busid = id;
      }
    }
    if (gotbus)
      return SUCCESS;
    return FAIL;
  }
 
  async command error_t BusArbitration.releaseBus[uint8_t id]() {
    atomic {
      if ((state == BUS_BUSY) && (busid == id)) {
        state = BUS_IDLE;

	// Post busReleased inside the if-statement so it's only posted if the
	// bus has actually been released.
	post busReleased();
      }
    }
    return SUCCESS;
  }

  default event error_t BusArbitration.busFree[uint8_t id]() {
    return SUCCESS;
  }

}

