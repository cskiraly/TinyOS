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
 * @date $Date: 2006-05-15 19:36:07 $ 
 */

#include "Timer.h"

module ReferenceTimerC {
  uses {
    interface Boot;
    interface Leds;
    interface Timer<TMilli> as Timer;
    interface SplitControl as TimeSyncControl;
    interface SplitControl as RadioControl;
  }
}
implementation {

  int counter;
  uint8_t schedule[4];

  event void Boot.booted() {
    counter = 0;
    schedule[0] = 8;
    schedule[1] = 4;
    schedule[2] = 2;
    schedule[3] = 4;
    call RadioControl.start();
  }

  event void RadioControl.startDone(error_t error) {
    call TimeSyncControl.start();
  }

  event void RadioControl.stopDone(error_t error) {
  }  

  event void TimeSyncControl.startDone(error_t error) {
    call Timer.startOneShot(schedule[counter++] * 100);
    call Leds.led2Toggle();
  }

  event void TimeSyncControl.stopDone(error_t error) {
  }

  event void Timer.fired() {
    call Timer.startOneShot(schedule[counter++] * 100);
    if(counter == 4) counter = 0;
    call Leds.led2Toggle();
  }
}
