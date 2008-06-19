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
 * $Revision: 1.1.2.2 $
 * $Date: 2006-01-27 02:38:05 $ 
 * ======================================================================== 
 */
 
/**
 * Please refer to TEP 115 for more information about this component and its
 * intended use.<br><br>
 *
 * This is the internal implementation of the standard power management
 * policy for managing the power states of non-virtualized devices.
 * Non-virtualized devices are shared using a parameterized Resource
 * interface, and are powered down according to some policy whenever there
 * are no more pending requests to that Resource.  The policy implemented
 * by this component is to power down a device as soon as it becomes free.
 * Such a policy is useful whenever a device has a negligible wake-up
 * latency.  There is no cost associated with waiting for the device to
 * power up, so it can be powered on and off as often as possible.
 * 
 * @author Kevin Klues (klueska@cs.wustl.edu)
 */
 
generic module AsyncPowerManagerP() {
  provides {
    interface Init;
  }
  uses {
    interface AsyncStdControl;

    interface PowerDownCleanup;
    interface Init as ArbiterInit;
    interface ResourceController;
    interface ArbiterInfo;
  }
}
implementation {

  norace struct {
    uint8_t stopping :1;
    uint8_t requested :1;
  } f; //for flags
  
  command error_t Init.init() {
    call ArbiterInit.init();
    call ResourceController.immediateRequest();
    return SUCCESS;
  }

  async event void ResourceController.requested() {
    if(f.stopping == FALSE) {
      call AsyncStdControl.start();
      call ResourceController.release();
    }
    else atomic f.requested = TRUE;    
  }

  async event void ResourceController.idle() {
    if(call ResourceController.immediateRequest() == SUCCESS) {
      atomic f.stopping = TRUE;
      call PowerDownCleanup.cleanup();
      call AsyncStdControl.stop();
    }
    if(f.requested == TRUE) {
      call AsyncStdControl.start();
      call ResourceController.release();
    }
    atomic {
      f.stopping = FALSE;
      f.requested = FALSE;
    }
  }

  event void ResourceController.granted() {
  }

  default async command void PowerDownCleanup.cleanup() {
  }
}