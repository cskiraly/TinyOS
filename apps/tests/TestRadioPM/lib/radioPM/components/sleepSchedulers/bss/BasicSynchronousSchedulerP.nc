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

 module BasicSynchronousSchedulerP {
  provides {
    interface SplitControl;
    interface DutyCycleTimes;
  }
  uses {
    interface Leds;
    interface Timer<TMilli> as Timer;
    interface SplitControl as TimeSyncControl;
    interface RadioPowerControl;
  }
 }

implementation {
  bool turnOn = TRUE;
  int delay;
  DutyCycleModes timerValue;
  DutyCycleModes last_timerValue;

  command error_t SplitControl.start() {
    return call TimeSyncControl.start();
  }

  command error_t SplitControl.stop() {
    call Timer.stop();
    call RadioPowerControl.on();
    call TimeSyncControl.stop();
    return SUCCESS;
  }

  command error_t DutyCycleTimes.turnOnFor(DutyCycleModes onMode) {
    turnOn = TRUE;
    timerValue = onMode;
    return SUCCESS;
  }
  command error_t DutyCycleTimes.turnOffFor(DutyCycleModes offMode) {
    turnOn = FALSE;
    timerValue = offMode;
    return SUCCESS;
  }

  event void Timer.fired() {
    signal DutyCycleTimes.ready();
    
    if(turnOn == TRUE)
      call RadioPowerControl.on();
    else call RadioPowerControl.off();

    delay = (call Timer.getNow() - call Timer.gett0()) - ((int)last_timerValue*DUTY_CYCLE_STEP - delay);
    call Timer.startOneShot((int)timerValue*DUTY_CYCLE_STEP - delay);
    last_timerValue = timerValue;   
  }

  event void TimeSyncControl.startDone(error_t error) {
    turnOn = TRUE;
    signal SplitControl.startDone(error);
    signal DutyCycleTimes.ready();
    
    if(turnOn == TRUE)
      call RadioPowerControl.on();
    else call RadioPowerControl.off();

    call Timer.startOneShot((int)timerValue*DUTY_CYCLE_STEP);
    last_timerValue = timerValue; 
  }

  event void TimeSyncControl.stopDone(error_t error) {
    signal SplitControl.stopDone(error);
  }

  event void RadioPowerControl.onDone(error_t error) {
    call Leds.led2On();
  }

  event void RadioPowerControl.offDone(error_t error) {
    call Leds.led2Off();
  }
}
