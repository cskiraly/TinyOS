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
 * $Revision: 1.1.2.1 $
 * $Date: 2005-12-06 22:53:04 $ 
 * ======================================================================== 
 *
 */
 
 /**
 * PowerManager generic module
 * 
 * @author Kevin Klues <klueska@cs.wustl.edu>
 */
 
generic module PowerManagerC() {
  provides {
    interface Init;
  }
  uses {
    interface StdControl;
    interface SplitControl;
    interface AsyncSplitControl;

    interface PowerDownCleanup;
    interface Init as ArbiterInit;
    interface Resource;
    interface ResourceRequested;
    interface Arbiter;
  }
}
implementation {

  norace struct {
   uint8_t stopping :1;
   uint8_t requested :1;
  } f; //for flags

  task void startTask() { 
    call StdControl.start();
    call SplitControl.start();
  }
  task void stopTask() { 
    call StdControl.stop(); 
    call SplitControl.stop(); 
  }

  command error_t Init.init() {
    f.stopping = FALSE;
    f.requested = FALSE;
    call ArbiterInit.init();
    call Resource.immediateRequest();
    return SUCCESS;
  }

  async event void ResourceRequested.requested() {
    if(f.stopping == FALSE)
      call AsyncSplitControl.start();
    else atomic f.requested = TRUE;
  }

  default async command error_t AsyncSplitControl.start() {
    post startTask();
    return SUCCESS;
  }
  default command error_t StdControl.start() {
    return SUCCESS;
  }
  default command error_t SplitControl.start() {
    signal SplitControl.startDone(SUCCESS);
    return SUCCESS;
  }

  async event void AsyncSplitControl.startDone(error_t error) {
    call Resource.release();
  }
  event void SplitControl.startDone(error_t error) {
    call Resource.release();
  }

  async event void Arbiter.idle() {
    if(call Resource.immediateRequest() == SUCCESS) {
      f.stopping = TRUE;
      call PowerDownCleanup.cleanup();
      call AsyncSplitControl.stop();
    }
  }

  async event void AsyncSplitControl.stopDone(error_t error) {
    if(f.requested == TRUE)
      call AsyncSplitControl.start();
    atomic {
      f.requested = FALSE;
      f.stopping = FALSE;
    }
  }
  event void SplitControl.stopDone(error_t error) {
    signal AsyncSplitControl.stopDone(error);
  }

  event void Resource.granted() {
  }

  default async command error_t AsyncSplitControl.stop() {
    post stopTask();
    return SUCCESS;
  }
  default command error_t StdControl.stop() {
    return SUCCESS;
  }
  default command error_t SplitControl.stop() {
    signal SplitControl.stopDone(SUCCESS);
    return SUCCESS;
  }

  default async command void PowerDownCleanup.cleanup() {
  }
}
