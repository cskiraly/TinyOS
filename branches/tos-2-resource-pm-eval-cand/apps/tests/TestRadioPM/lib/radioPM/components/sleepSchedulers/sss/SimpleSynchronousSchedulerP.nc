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

module SimpleSynchronousSchedulerP {
  provides {
    interface Init;
    interface SplitControl;
    interface RadioDutyCycling;
  }
  uses {
    interface SplitControl as TimeSyncControl;
    interface RadioPowerControl;
    interface Timer<TMilli> as Timer;
    interface Leds;
  }
}
implementation 
{
  uint16_t onTime = 300;
  uint16_t offTime = 0;

  struct {
    uint8_t timerForOn : 1 ;
    uint8_t isOn : 1 ;
    uint8_t radioOn : 1 ;
  } f; //for flags

  /* Time lookups */

  uint16_t setTime(DutyCycleModes mode) {
    return mode * DUTY_CYCLE_STEP;
  }

  command error_t Init.init() {
    f.radioOn = FALSE;
    f.timerForOn = TRUE;
    f.isOn = FALSE;
    return SUCCESS;
  }

  command error_t SplitControl.start() {
    return call TimeSyncControl.start();
  }

  event void TimeSyncControl.startDone(error_t error) {
    f.isOn = TRUE;
    f.timerForOn = TRUE;
    if(offTime > 0 && onTime > 0)
      call Timer.startOneShot(onTime);
    call RadioPowerControl.on();   
    signal SplitControl.startDone(error); 
  }

  command error_t SplitControl.stop() {
    f.isOn = FALSE;
    call Timer.stop();
    return call TimeSyncControl.stop();
  }

  event void TimeSyncControl.stopDone(error_t error) {
    signal SplitControl.stopDone(error);
  }  

  event void Timer.fired() {
    uint32_t timer;
    atomic {
      if(f.timerForOn == TRUE ) {
        call RadioPowerControl.off();
        timer = offTime;
      }
      else {
        call RadioPowerControl.on();
        timer = onTime;
      }
      f.timerForOn = !f.timerForOn;
    }
    call Timer.startOneShot(timer);
  }
  
  event void RadioPowerControl.offDone(error_t error) {
    if(error == SUCCESS) {
      atomic f.radioOn = FALSE;
      call Leds.led0Off();
      signal RadioDutyCycling.beginOffTime();
    }
  }

  event void RadioPowerControl.onDone(error_t error) {
    if(error == SUCCESS) {
      atomic f.radioOn = TRUE;
      call Leds.led0On();
      signal RadioDutyCycling.beginOnTime();
    }
  }

  command error_t RadioDutyCycling.setModes(DutyCycleModes onMode, DutyCycleModes offMode) {
    atomic if(f.isOn == TRUE) return FAIL;
    atomic onTime = setTime(onMode);
    atomic offTime = setTime(offMode);
    return SUCCESS;
  }

  /**
   * Set the current Dutycycling on time mode
   * @return SUCCESS if the mode was successfully changed
   */
  command error_t RadioDutyCycling.setOnTimeMode(DutyCycleModes onMode) {
    atomic if(f.isOn == TRUE) return FAIL;
    atomic onTime = setTime(onMode);
    return SUCCESS;
  }

  /**
   * Set the current Dutycycling off time mode
   * @return SUCCESS if the mode was successfully changed
   */
  command error_t RadioDutyCycling.setOffTimeMode(DutyCycleModes offMode) {
    atomic if(f.isOn == TRUE) return FAIL;
    atomic offTime = setTime(offMode);
    return SUCCESS;
  }
}
