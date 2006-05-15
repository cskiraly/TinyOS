/*
 * "Copyright (c) 2005 Washington University in St. Louis.
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 *
 * IN NO EVENT SHALL WASHINGTON UNIVERSITY IN ST. LOUIS BE LIABLE TO ANY PARTY 
 * FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING 
 * OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF WASHINGTON 
 * UNIVERSITY IN ST. LOUIS HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * WASHINGTON UNIVERSITY IN ST. LOUIS SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND WASHINGTON UNIVERSITY IN ST. LOUIS HAS NO 
 * OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR
 * MODIFICATIONS."
 */

/**
 *
 * @author Kevin Klues (klueska@cs.wustl.edu)
 * @version $Revision: 1.1.2.1 $
 * @date $Date: 2006-05-15 19:36:08 $ 
 */

module DutyCycleTimesTableC {
  provides {
    interface DutyCycleTimesTable;
    interface DutyCycleTimes[uint8_t];
  }
}

implementation {

  uint8_t table[DUTY_CYCLE_TIMES_NUM_COLS][uniqueCount(RADIO_PM_DUTY_CYCLE_TIMES)];

  command uint8_t* DutyCycleTimesTable.getOnTimeModes() {
    return table[DUTY_CYCLE_TIMES_ON_TIME_MODE_INDEX];
  }

  command uint8_t* DutyCycleTimesTable.getOffTimeModes() {
    return table[DUTY_CYCLE_TIMES_OFF_TIME_MODE_INDEX];
  }

  command error_t DutyCycleTimes.turnOnFor[uint8_t n](DutyCycleModes onTime) {
    table[DUTY_CYCLE_TIMES_ON_TIME_MODE_INDEX][n] = onMode;
    return SUCCESS;
  }
  
  command error_t DutyCycleTimes.turnOffFor[uint8_t n](DutyCycleModes offMode) {
    table[DUTY_CYCLE_TIMES_OFF_TIME_MODE_INDEX][n] = offMode;
    return SUCCESS;
  }

  command void DutyCycleTimesTable.signalReady(uint8_t i) {
    signal DutyCycleTimes.ready[i]();
  }

  default event void DutyCycleTimes.ready() {
  }
}

