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
 * @date $Date: 2006-05-15 19:36:09 $
 */

module RadioPmP {
  uses {
    interface Boot as MainBoot;
    interface SplitControl as AMRadioControl;
    interface SplitControl as AggregatorControl;
    interface SplitControl as PmPolicyControl[uint8_t];
    interface Leds;
  }
}

implementation {

  uint8_t started = 0;

  event void MainBoot.booted() {
    call AMRadioControl.start();
  }

  event void AMRadioControl.startDone(error_t error) {
    int i;
    if (uniqueCount(RADIO_PM_PROTOCOL) == 0){
		call Leds.led2On();
      call AggregatorControl.start();
    }else {
      for(i = 0; i < uniqueCount(RADIO_PM_PROTOCOL); i++){
        call Leds.led0On();
        call PmPolicyControl.start[i]();
	  }
    }
  }

  event void AMRadioControl.stopDone(error_t error) {
  }

  event void PmPolicyControl.startDone[uint8_t i](error_t error) {
    if(++started == uniqueCount(RADIO_PM_PROTOCOL)){
		call Leds.led1On();
      call AggregatorControl.start();
  }
  }

  event void PmPolicyControl.stopDone[uint8_t i](error_t error) {
    if(--started == 0)
      call AggregatorControl.stop();
  }

  event void AggregatorControl.startDone(error_t error) {
  }

  event void AggregatorControl.stopDone(error_t error) {
    call AMRadioControl.stop();
  }

  default command error_t PmPolicyControl.start[uint8_t i]() {
    return SUCCESS;
  }

  default command error_t PmPolicyControl.stop[uint8_t i]() {
    return SUCCESS;
  }
}

