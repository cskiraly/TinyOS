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
 * $Revision: 1.1.2.2 $
 * $Date: 2005-12-01 04:51:32 $ 
 * ======================================================================== 
 *
 */
 
 /**
 * PowerManager generic module
 * 
 * @author Kevin Klues <klueska@cs.wustl.edu>
 */
 
generic module DeferredPowerManagerP(uint32_t delay) {
  provides {
    interface Init;
  }
  uses {
    interface Init as ArbiterInit;
    interface StdControl;
    interface Resource;
    interface ResourceRequested;
    interface Arbiter;
    interface Timer<TMilli> as TimerMilli;
  }
}
implementation {

  command error_t Init.init() {
    call ArbiterInit.init();
    call Resource.immediateRequest();
    return SUCCESS;
  }

  event void ResourceRequested.requested() {
     call StdControl.start();
     call Resource.release();
  }

  event void Arbiter.idle() {
    if(!(call Arbiter.inUse()))
      call TimerMilli.startOneShot(delay);
  }

  event void TimerMilli.fired() {
    if(call Resource.immediateRequest() == SUCCESS)
      call StdControl.stop();
  }

  event void Resource.granted() {
  }
}
