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

/* "Copyright (c) 2000-2005 The Regents of the University  of California.  
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
 * Copyright (c) 2002-2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
/**
 * A rewrite of the low-power-listening CC1000 radio stack.
 * This file contains the CSMA and low-power listening logic. Actual
 * packet transmission and reception is in SendReceive.
 *
 * This code has some degree of platform-independence, via the
 * CC1000Control, RSSIADC and SpiByteFifo interfaces which must be provided
 * by the platform. However, these interfaces may still reflect some
 * particularities of the mica2 hardware implementation.
 *
 * @author Philip Buonadonna
 * @author Jaein Jeong
 * @author Joe Polastre
 * @author David Gay
 * @author Kevin Klues
 */

#include "LowPowerListening.h"

module LowPowerListeningP {
  provides {
    interface SplitControl;
    interface LowPowerListening;
  }
  uses {
    interface PreambleLength;
    interface RadioPowerControl;
    interface ChannelMonitor;
    interface Timer<TMilli> as Timer;
    interface Leds;
  }
}
implementation 
{

  uint8_t lplTxPower=0, lplRxPower=0;
  uint16_t sleepTime = 0xFFFF;

  /* LPL preamble length and sleep time computation */

  uint16_t computePreambleLength() {
    return
      (uint16_t)LPL_PreambleLength[lplTxPower * 2] << 8 | LPL_PreambleLength[lplTxPower * 2 + 1];
  }
  
  void setPreambleLength() {
    call PreambleLength.set(computePreambleLength());
  }

  void setSleepTime() {
    atomic sleepTime =
      (uint16_t)LPL_SleepTime[lplRxPower *2 ] << 8 | LPL_SleepTime[lplRxPower * 2 + 1];
  }

  async event uint16_t PreambleLength.query() {
    return computePreambleLength();
  }

  command error_t SplitControl.start() {
    uint8_t lplRxPower_temp;
    setSleepTime();
    atomic lplRxPower_temp = lplRxPower;
    if(lplRxPower_temp > 0)
      call Timer.startOneShot(sleepTime);
    signal SplitControl.startDone(SUCCESS);
    return SUCCESS;
  }

  command error_t SplitControl.stop() {
    /* Disable the Csma Radio I am connected to */
    atomic sleepTime = 0xFFFF;
    signal SplitControl.stopDone(SUCCESS);
    return SUCCESS;
  }

  event void Timer.fired() {
    call ChannelMonitor.check();
    call Timer.startOneShot(sleepTime);
  }

  async event void ChannelMonitor.free() {
    call RadioPowerControl.off();
  }

  async event void ChannelMonitor.busy() {
    call RadioPowerControl.on();
  }

  event void ChannelMonitor.error() {
    call RadioPowerControl.off();
  }

  async command error_t LowPowerListening.setListeningMode(uint8_t power) {
    if (power >= LPL_STATES)
      return FAIL;

    if(sleepTime != 0xFFFF) 
      return FAIL;
    atomic {
      if (lplRxPower == lplTxPower)
        lplTxPower = power;
      lplRxPower = power;
    }
    return SUCCESS;
  }

  async command uint8_t LowPowerListening.getListeningMode() {
    atomic return lplRxPower;
  }

  async command error_t LowPowerListening.setTransmitMode(uint8_t power) {
    if (power >= LPL_STATES)
      return FAIL;

    atomic {
      lplTxPower = power;
      setPreambleLength();
    }
    return SUCCESS;
  }

  async command uint8_t LowPowerListening.getTransmitMode() {
    atomic return lplTxPower;
  }

  async command error_t LowPowerListening.setPreambleLength(uint16_t bytes) {
    call PreambleLength.set(bytes);
    return SUCCESS;
  }

  async command uint16_t LowPowerListening.getPreambleLength() {
    return call PreambleLength.get();
  }

  async command error_t LowPowerListening.setCheckInterval(uint16_t ms) {
    atomic sleepTime = ms;
    return SUCCESS;
  }

  async command uint16_t LowPowerListening.getCheckInterval() {
    atomic return sleepTime;
  }

  event void RadioPowerControl.onDone(error_t error) {
    call Leds.led0On();
  }
  event void RadioPowerControl.offDone(error_t error) {
    call Leds.led0Off();
  }
}
