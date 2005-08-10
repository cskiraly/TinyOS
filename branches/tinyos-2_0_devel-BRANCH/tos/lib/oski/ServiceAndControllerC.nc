// $Id: ServiceAndControllerC.nc,v 1.1.2.1 2005-08-10 15:54:39 scipio Exp $
/*									tab:4
 * "Copyright (c) 2005 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 * Copyright (c) 2004 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */


/**
 * A generic status controller that follows an AND rule. The controller
 * provides access to the power/activity state of an underlying shared
 * service and coordinates the requirements of all of the services's
 * clients. It follows the rule that if all clients need the service
 * to be active (through the Service.start() command), then it turns on
 * the service, or keeps it on. However, if any client needs the service
 * to be off (called stop() or not called start()), then
 * it turns it off. start() and stop() are both idempotent operations:
 * a client calling Service.start() twice has the same effect as
 * calling it once.
 *
 * The controller operates by keeping track of the state of all of its
 * clients (active or not) and managing the underlying component
 * appropriately with the SplitControl interface. The controller
 * assumes that only one SplitControl command can be in progress at
 * any time: if a state change occurs while the controller is
 * in the middle of a split phase call, it delays the action until
 * the completion of the call.
 *
 * If SplitControl calls to the underlying service fail, then the
 * controller silently fails. For example, if a client calls
 * Service.start() such that the underlying service should be started
 * (before this, all clients were inactive), then the controller will
 * call SplitControl.start(). The controller needs to keep track of
 * whether the service is active in case the call to
 * SplitControl.start() fails. If that happens, then the client's bit
 * will be set, but status.active will be FALSE. The ServiceController
 * maintains no timers; whenever an call or signal is made to the
 * controller, it modifies the corresponding state and checks if it
 * needs to enact a state change on the underlying service
 * (enactStateChange()). So in the case when a call to SplitControl
 * fails, the controller will not try to rectify the situation until
 * the next time it is called or signalled.
 *
 * @author Philip Levis
 * @date   May 16 2005
 */ 

generic module ServiceAndControllerC(char* strID) {
  provides {
    interface Service[uint8_t id];
    interface ServiceNotify;
  }
  uses {
    interface SplitControl;
  }
}

implementation {

  enum {
    STATUS_BITS = uniqueCount(strID),
    STATUS_BYTES = (STATUS_BITS + 7) / 8,
  };

  typedef struct {
    uint8_t busy:1;
    uint8_t active:1;
  } AndControllerService;
  
  // Bits are stored big-endian. Bit 0 is the 0th bit of the last
  // element, while bit 18 is the 2nd bit of the third to last
  // element.
  uint8_t bitmask[STATUS_BYTES];

  // Assume that we are initially busy (the rest of TinyOS is
  // initializing the underlying service, but that it isn't started
  // (that's under our control).
  AndControllerService status = {
    TRUE,
    FALSE
  };
  
  enum {
    STATUS_BITS = uniqueCount(strID),
    STATUS_BYTES = (STATUS_BITS + 7) / 8,
  };
  
  bool isNotFull() {
    int i;
    for (i = 0; i < STATUS_BYTES; i++) {
      if (bitmask[i] == 0) {
	return TRUE;
      }
    }
    return FALSE;
  }

  uint8_t bitToByte(uint8_t bit) {
    return (STATUS_BYTES - (bit / 8) - 1);
  }
  
  void setBit(uint8_t bit) {
    bitmask[bitToByte(bit)] |= (1 << (bit % 8));
  }

  void clearBit(uint8_t bit) {
    bitmask[bitToByte(bit)] &= ~(1 << (bit % 8));
  }

  void enactStateChange() {
    if (status.busy) {return;}
    if (isNotFull() && status.active) {
      if (call SplitControl.stop() == SUCCESS) {
	status.busy = TRUE;
      }
    }
    if (!isNotFull() && !status.active) {
      if (call SplitControl.start() == SUCCESS) {
	status.busy = TRUE;
      }
    }
  }

  command bool Service.isRunning() {
    return (status.active)? TRUE:FALSE;
  }
  
  command void Service.start[uint8_t id]() {
    setBit(id);
    enactStateChange();
  }

  event result_t SplitControl.startDone() {
    status.busy = FALSE;
    status.active = TRUE;
    signal ServiceNotify.started();
    /* Invoke enactStateChange() in case clients tried to stop the
     * service while it was being started. */
    enactStateChange();
  }

  command void Service.stop[uint8_t id]() {
    clearBit(id);
    enactStateChange();
  }

  event result_t SplitControl.stopDone() {
    status.busy = FALSE;
    status.active = FALSE;
    signal ServiceNotify.stopped();
    /* Invoke enactStateChange() in case clients tried to start the
     * service while it was being stopped. */
    enactStateChange();            
  }
  
  event result_t SplitControl.initDone() {
    status.busy = FALSE;
    /* Invoke enactStateChange() in case there are pending requests
     * to start the service. */
    enactStateChange();
  }
  
}
