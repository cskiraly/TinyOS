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

module RadioDutyCyclingTableC {
  provides {
    interface RadioDutyCyclingTable;
    interface RadioDutyCycling[uint8_t];
  }
}

implementation {

  uint8_t table[RADIO_DUTY_CYCLING_NUM_COLS][uniqueCount(RADIO_PM_RADIO_DUTY_CYCLING)];

  command uint8_t* RadioDutyCyclingTable.getOnTimeModes() {
    return table[RADIO_DUTY_CYCLING_ON_TIME_MODE_INDEX];
  }

  command uint8_t* RadioDutyCyclingTable.getOffTimeModes() {
    return table[RADIO_DUTY_CYCLING_OFF_TIME_MODE_INDEX];
  }

  command error_t RadioDutyCycling.setModes[uint8_t n](DutyCycleModes onMode, DutyCycleModes offMode) {
    table[RADIO_DUTY_CYCLING_ON_TIME_MODE_INDEX][n] = onMode;
    table[RADIO_DUTY_CYCLING_OFF_TIME_MODE_INDEX][n] = offMode;
    return SUCCESS;
  }
  
  command error_t RadioDutyCycling.setOnTimeMode[uint8_t n](DutyCycleModes onMode) {
    table[RADIO_DUTY_CYCLING_ON_TIME_MODE_INDEX][n] = onMode;
    return SUCCESS;
  }
  
  command error_t RadioDutyCycling.setOffTimeMode[uint8_t n](DutyCycleModes offMode) {
    table[RADIO_DUTY_CYCLING_OFF_TIME_MODE_INDEX][n] = offMode;
    return SUCCESS;
  }

  command void RadioDutyCyclingTable.signalBeginOnTime(uint8_t i) {
    signal RadioDutyCycling.beginOnTime[i]();
  }

  command void RadioDutyCyclingTable.signalBeginOffTime(uint8_t i) {
    signal RadioDutyCycling.beginOffTime[i]();
  }

  default event void RadioDutyCycling.beginOffTime[uint8_t n]() {
  }

  default event void RadioDutyCycling.beginOnTime[uint8_t n]() {
  }
}

