//$Id: CaptureM.nc,v 1.1.2.1 2005-04-21 22:09:42 jpolastre Exp $

/* "Copyright (c) 2000-2003 The Regents of the University of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement
 * is hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY
 * OF CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 */

/**
 * @author Joe Polastre
 */

generic module CaptureM() {
  provides interface Capture;
  uses interface MSP430Control;
  uses interface MSP430Capture;
  uses interface MSP430GeneralIO;
  uses interface Counter<T32khz> as LocalTime;
}
implementation {
  async command error_t Capture.enableCapture(bool low_to_high) {
    uint8_t _direction;
    atomic {
      call MSP430GeneralIO.selectModuleFunc();
      call MSP430Control.disableEvents();
      if (low_to_high) _direction = MSP430TIMER_CM_RISING;
      else _direction = MSP430TIMER_CM_FALLING;
      call MSP430Control.setControlAsCapture(_direction);
      call MSP430Capture.clearOverflow();
      call MSP430Control.clearPendingInterrupt();
      call MSP430Control.enableEvents();
    }
    return SUCCESS;
  }

  async command error_t Capture.disable() {
    atomic {
      call MSP430Control.disableEvents();
      call MSP430Control.clearPendingInterrupt();
      call MSP430Control.selectIOFunc();
    }
    return SUCCESS;
  }

  async event void MSP430Capture.captured(uint32_t time) {
    result_t val = SUCCESS;
    call MSP430Control.clearPendingInterrupt();
    val = signal SFD.captured(time);
    if (val == FAIL) {
      call MSP430Control.disableEvents();
      call MSP430Control.clearPendingInterrupt();
    }
    else {
      if (call MSP430Capture.isOverflowPending())
        call MSP430Capture.clearOverflow();
    }
  }

  // not worried about overflows at this time
  event void LocalTime.overflow() { } 

  // stop the timer if no one is wired to it
  default async event error_t SFD.captured(uint32_t val) { return FAIL; }
}