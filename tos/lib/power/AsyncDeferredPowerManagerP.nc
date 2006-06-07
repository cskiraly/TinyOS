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
 */
 
/*
 * - Revision -------------------------------------------------------------
 * $Revision: 1.1.2.2.6.2 $
 * $Date: 2006-06-07 10:47:17 $ 
 * ======================================================================== 
 */
 
/**
 * Please refer to TEP 115 for more information about this component and its
 * intended use.<br><br>
 *
 * This is the internal implementation of the deffered power management
 * policy for managing the power states of non-virtualized devices.
 * Non-virtualized devices are shared using a parameterized Resource
 * interface, and are powered down according to some policy whenever there
 * are no more pending requests to that Resource.  The policy implemented
 * by this component is to delay the power down of a device by some contant
 * factor.  Such a policy is useful whenever a device has a long wake-up
 * latency.  The cost of waiting for the device to power up can be
 * avoided if the device is requested again before some predetermined
 * amount of time.
 *
 * @param <b>delay</b> -- The amount of time the power manager should wait
 *                        before shutting down the device once it is free.
 * 
 * @author Kevin Klues (klueska@cs.wustl.edu)
 */
 
generic module AsyncDeferredPowerManagerP(uint32_t delay) {
  provides {
    interface Init;
  }
  uses {
    interface AsyncStdControl;

    interface PowerDownCleanup;
    interface ResourceController;
    interface ArbiterInfo;
    interface Timer<TMilli> as TimerMilli;
  }
}
implementation {

  norace struct {
   uint8_t stopping :1;
  } f; //for flags

  task void timerTask() { 
    call TimerMilli.startOneShot(delay); 
  }

  command error_t Init.init() {
    f.stopping = FALSE;
    call ResourceController.request();
    return SUCCESS;
  }

  event void ResourceController.requested() {
    call AsyncStdControl.start();
    call ResourceController.release();
  }

  async event void ResourceController.immediateRequested() {
    if(f.stopping == FALSE) {
      call AsyncStdControl.start();
      call ResourceController.immediateRelease();
    }
  }  

  async event void ResourceController.idle() {
    if(!(call ArbiterInfo.inUse()))
      post timerTask();
  }

  event void TimerMilli.fired() {
    if(call ResourceController.request() == SUCCESS) {
      f.stopping = TRUE;
      call PowerDownCleanup.cleanup();
      call AsyncStdControl.stop();
      f.stopping = FALSE;
    }    
  }

  event void ResourceController.granted() {
  }

  default async command void PowerDownCleanup.cleanup() {
  }
}
