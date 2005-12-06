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
 *
 * - Revision -------------------------------------------------------------
 * $Revision: 1.1.2.3 $
 * $Date: 2005-12-06 22:11:54 $ 
 * ======================================================================== 
 *
 */
 
 /**
 * MyComponentP module
 *
 * @author Kevin Klues (klueska@cs.wustl.edu)
 */
 
module MyComponentP {
  provides {
    interface SplitControl;
    interface StdControl;
    interface AsyncSplitControl;
  }
  uses {
    interface Leds;
    interface Timer<TMilli> as StartTimer;
    interface Timer<TMilli> as StopTimer;
  }
}
implementation {

  #define START_DELAY 10
  #define STOP_DELAY 10

  command error_t SplitControl.start() {
    call StartTimer.startOneShot(START_DELAY);
    return SUCCESS;
  }

  event void StartTimer.fired() {
    call Leds.led0On();
    signal SplitControl.startDone(SUCCESS);
  }

  command error_t SplitControl.stop() {
    call StopTimer.startOneShot(STOP_DELAY);
    return SUCCESS;
  }

  event void StopTimer.fired() {
    call Leds.led0Off();
    signal SplitControl.stopDone(SUCCESS);
  }

  command error_t StdControl.start() {
    call Leds.led0On();
    return SUCCESS;
  }

  command error_t StdControl.stop() {
    call Leds.led0Off();
    return SUCCESS;
  }

  async command error_t AsyncSplitControl.start() {
    call Leds.led0On();
    signal AsyncSplitControl.startDone(SUCCESS);
    return SUCCESS;
  }

  async command error_t AsyncSplitControl.stop() {
    call Leds.led0Off();
    signal AsyncSplitControl.stopDone(SUCCESS);
    return SUCCESS;
  }

  default event void SplitControl.startDone(error_t error) {}
  default event void SplitControl.stopDone(error_t error) {}
  default async event void AsyncSplitControl.startDone(error_t error) {}
  default async event void AsyncSplitControl.stopDone(error_t error) {}
}

