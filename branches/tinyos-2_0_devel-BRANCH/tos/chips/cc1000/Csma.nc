// $Id: Csma.nc,v 1.1.2.2 2005-06-02 22:55:37 idgay Exp $

/*									tab:4
 * "Copyright (c) 2000-2005 The Regents of the University  of California.  
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
 *
 * This code has some degree of platform-independence, via the
 * CC1000Control, RSSIADC and SpiByteFifo interfaces. However, these
 * interfaces may be still somewhat platform-dependent.
 *
 * @author Philip Buonadonna
 * @author Jaein Jeong
 * @author Joe Polastre
 * @author David Gay
 */
  
#include "TOSMsg.h"
#include "crc.h"
#include "CC1000Const.h"
#include "Timer.h"

module Csma {
  provides {
    interface Init;
    interface SplitControl;
    interface CSMAControl;
    interface CSMABackoff;
    interface LowPowerListening;

    interface ByteRadio;
  }
  uses {
    interface Init as ByteRadioInit;
    interface StdControl as ByteRadioControl;

    //interface PowerManagement;
    interface CC1000Control;
    interface CC1000Squelch;
    interface Random;
    interface HPLCC1000Spi;
    interface Timer<TMilli> as WakeupTimer;

    interface AcquireDataNow as RssiNoiseFloor;
    interface AcquireDataNow as RssiCheckChannel;
    interface AcquireDataNow as RssiPulseCheck;
    async command void cancelRssi();
  }
}
implementation 
{
  enum {
    DISABLED_STATE,
    IDLE_STATE,
    RX_STATE,
    PRETX_STATE,
    TX_STATE,
    POWERDOWN_STATE,
    PULSECHECK_STATE
  };

  enum {
    TIME_AFTER_CHECK =  30,
  };

  uint8_t radioState = DISABLED_STATE;
  struct {
    uint8_t ccaOff : 1;
    uint8_t lplReceive : 1;
    uint8_t txPending : 1;
  } f; // f for flags
  uint16_t count;
  uint8_t clearCount;

  int16_t macDelay;

  uint8_t lplTxPower, lplRxPower;
  uint16_t sleepTime;

  uint16_t rssiForSquelch;

  task void setWakeupTask();

  void enterIdleState() {
    call cancelRssi();
    radioState = IDLE_STATE;
    count = 0;
  }

  void enterIdleStateSetWakeup() {
    enterIdleState();
    post setWakeupTask();
  }

  void enterDisabledState() {
    call cancelRssi();
    radioState = DISABLED_STATE;
  }

  void enterPowerDownState() {
    call cancelRssi();
    radioState = POWERDOWN_STATE;
  }

  void enterPulseCheckState() {
    radioState = PULSECHECK_STATE;
    count = 0;
  }

  void enterRxState() {
    call cancelRssi();
    radioState = RX_STATE;
  }

  void enterPreTxState() {
    call cancelRssi();
    radioState = PRETX_STATE;
    count = clearCount = 0;
  }

  void enterTxState() {
    radioState = TX_STATE;
  }

  /* Wakeup timer */
  /* ------------ */

  void setWakeup() {
    switch (radioState)
      {
      case IDLE_STATE: case PRETX_STATE: case RX_STATE:
	/* We se the timers in PreTx and Sync states because these
	   may abort back to IDLE. When doing that, they don't 
	   reset timers (to avoid perturbing the lpl-wakeup timeout).
	   So we always set the next timer here, even though we're
	   likely to move to the Rx or Tx states. */
	if (call CC1000Squelch.settled())
	  {
	    if (lplRxPower == 0 || f.txPending)
	      call WakeupTimer.startOneShotNow(CC1K_SquelchIntervalSlow);
	    else if (f.lplReceive)
	      /* Wait TIME_AFTER_CHECK ms for a message, then give up. */
	      call WakeupTimer.startOneShotNow(TIME_AFTER_CHECK);
	    else
	      call WakeupTimer.startOneShotNow(sleepTime);
	  }
	else
	  call WakeupTimer.startOneShotNow(CC1K_SquelchIntervalFast);
	break;
      case PULSECHECK_STATE:
	call WakeupTimer.startOneShotNow(1);
	break;
      case POWERDOWN_STATE:
	call WakeupTimer.startOneShotNow(sleepTime);
	break;
      }
  }

  task void setWakeupTask() {
    atomic setWakeup();
  }

  event void WakeupTimer.fired() {
    atomic 
      {
	f.lplReceive = FALSE;

	switch (radioState)
	  {
	  case IDLE_STATE:
	    call cancelRssi();
	    call RssiNoiseFloor.getData();
	    break;

	  case POWERDOWN_STATE:
	    enterPulseCheckState();
	    call CC1000Control.biasOn();
	    break;

	  case PULSECHECK_STATE:
	    call CC1000Control.rxMode();
	    call RssiPulseCheck.getData();
	    uwait(80);
	    //call CC1000Control.biasOn();
	    //call CC1000StdControl.stop();
	    return; // don't set wakeup timer
	  }

	setWakeup();
      }
  }

  /* Low-power listening stuff */
  /*---------------------------*/
  void setPreambleLength() {
    uint16_t len =
      (uint16_t)read_uint8_t(&CC1K_LPL_PreambleLength[lplTxPower * 2]) << 8
      | read_uint8_t(&CC1K_LPL_PreambleLength[lplTxPower * 2 + 1]);
    signal ByteRadio.setPreambleLength(len);
  }

  void setSleepTime() {
    sleepTime =
      (uint16_t)read_uint8_t(&CC1K_LPL_SleepTime[lplRxPower *2 ]) << 8 |
      read_uint8_t(&CC1K_LPL_SleepTime[lplRxPower * 2 + 1]);
  }

  void lplSleep() {
    enterPowerDownState();
    call HPLCC1000Spi.disableIntr();
    call CC1000Control.off();
    setWakeup();
  }

  void lplSendWakeup() {
    enterIdleStateSetWakeup();
    call CC1000Control.coreOn();
    //uwait(2000);
    call CC1000Control.biasOn();
    uwait(200);
    call CC1000Control.rxMode();
    call HPLCC1000Spi.rxMode();
    call HPLCC1000Spi.enableIntr();
  }

  task void sleepCheck() {
    atomic
      if (f.txPending)
	{
	  if (radioState == PULSECHECK_STATE || radioState == POWERDOWN_STATE)
	    lplSendWakeup();
	}
      else if (lplRxPower > 0 && call CC1000Squelch.settled() &&
	       (radioState == IDLE_STATE || radioState == PULSECHECK_STATE))
	lplSleep();
  }

  task void adjustSquelch();

  async event void RssiPulseCheck.dataReady(uint16_t data) {
    //if(data > call CC1000Squelch.get() - CC1K_SquelchBuffer)
    if (data > call CC1000Squelch.get() - (call CC1000Squelch.get() >> 2))
      {
	// don't be too agressive (ignore really quiet thresholds).
	if (data < call CC1000Squelch.get() + (call CC1000Squelch.get() >> 3))
	  {
	    // adjust the noise floor level, go back to sleep.
	    rssiForSquelch = data;
	    post adjustSquelch();
	  }
	post sleepCheck();
      }
    else if (count++ > 5)
      {
	//go to the idle state since no outliers were found
	enterIdleStateSetWakeup();
	f.lplReceive = TRUE;
	call CC1000Control.rxMode();
	call HPLCC1000Spi.rxMode();     // SPI to miso
	call HPLCC1000Spi.enableIntr(); // enable spi interrupt
      }
    else
      {
	call RssiPulseCheck.getData();
	uwait(80);
      }
  }

  event void RssiPulseCheck.error(uint16_t info) {
    /* Just give up on this interval. */
    post sleepCheck();
  }

  command error_t Init.init() {
    call HPLCC1000Spi.initSlave(); // set spi bus to slave mode
    call CC1000Control.init();
    call ByteRadioInit.init();

    return SUCCESS;
  }

  task void startStopDone() {
    uint8_t s;

    // Save a byte of RAM by sharing start/stopDone task
    atomic s = radioState;
    if (s == DISABLED_STATE)
      signal SplitControl.stopDone(SUCCESS);
    else
      signal SplitControl.startDone(SUCCESS);
  }

  command error_t SplitControl.start() {
    atomic 
      if (radioState == DISABLED_STATE)
	{
	  call ByteRadioControl.start();
	  enterIdleStateSetWakeup();
	  f.lplReceive = f.txPending = FALSE;
	  setPreambleLength();
	  setSleepTime();
	}
      else
	return SUCCESS;

    call CC1000Control.coreOn();
    uwait(2000);
    call CC1000Control.biasOn();
    uwait(200);
    call HPLCC1000Spi.rxMode();
    call CC1000Control.rxMode();
    call HPLCC1000Spi.enableIntr();

    post startStopDone();

    return SUCCESS;
  }

  command error_t SplitControl.stop() {
    atomic 
      {
	call ByteRadioControl.stop();
	enterDisabledState();
	call CC1000Control.off();
	call HPLCC1000Spi.disableIntr();
      }
    call WakeupTimer.stop();
    post startStopDone();
    return SUCCESS;
  }

  command void ByteRadio.rts() {
    atomic
      {
	if (!f.ccaOff)
	  macDelay = signal CSMABackoff.initial(NULL);
	else
	  macDelay = 0;
	f.txPending = TRUE;
	f.lplReceive = FALSE;

	if (radioState == POWERDOWN_STATE)
	  post sleepCheck();
      }
  }

  async command void ByteRadio.sendDone() {
    f.txPending = FALSE;
    enterIdleStateSetWakeup();
  }

  /* Basic SPI functions */

  void idleData(uint8_t in) {
    // Look for enough preamble bytes
    if (in == 0xaa || in == 0x55)
      {
	/* XXX: reset macDelay if txPending? */
	count++;
	if (count > CC1K_ValidPrecursor)
	  {
	    enterRxState();
	    signal ByteRadio.cd();
	  }
      }
    else if (f.txPending)
      if (macDelay <= 1)
	{
	  enterPreTxState();
	  call RssiCheckChannel.getData();
	}
      else
	--macDelay;
  }

  void preTxData(uint8_t in) {
    // If we detect a preamble when we're trying to send, abort.
    if (in == 0xaa || in == 0x55)
      {
	macDelay = signal CSMABackoff.congestion(NULL);
	enterIdleState();
	// we could set count to 1 here (one preamble byte seen).
	// count = 1;
      }
  }

  async command void ByteRadio.rxAborted() {
    enterIdleState();
  }

  async command void ByteRadio.rxDone() {
    enterIdleStateSetWakeup();
  }

  async event void HPLCC1000Spi.dataReady(uint8_t data) {
    switch (radioState)
      {
      default: break;
      case IDLE_STATE: idleData(data); break;
      case PRETX_STATE: preTxData(data); break;
      }
  }

  /* Noise floor stuff */
  /*-------------------*/

  task void adjustSquelch() {
    uint16_t squelchData;

    atomic squelchData = rssiForSquelch;
    call CC1000Squelch.adjust(squelchData);
  }

  async event void RssiNoiseFloor.dataReady(uint16_t data) {
    rssiForSquelch = data;
    post adjustSquelch();
    post sleepCheck();
  }

  event void RssiNoiseFloor.error(uint16_t info) {
    /* We just ignore failed noise floor measurements */
    post sleepCheck();
  }

  async event void RssiCheckChannel.dataReady(uint16_t data) {
    count++;
    if (data > call CC1000Squelch.get() + CC1K_SquelchBuffer)
      clearCount++;
    else
      clearCount = 0;

    // if the channel is clear or CCA is disabled, GO GO GO!
    if (clearCount >= 1 || f.ccaOff)
      {
	enterTxState();
	signal ByteRadio.cts();
      }
    else if (count == CC1K_MaxRSSISamples)
      {
	macDelay = signal CSMABackoff.congestion(NULL);
	enterIdleState();
      }
    else 
      call RssiCheckChannel.getData();
  }

  event void RssiCheckChannel.error(uint16_t info) {
    /* We'll retry the transmission at the next SPI event. */
    atomic enterIdleState();
  }

  async command message_t* CSMAControl.HaltTx() {
    /* We simply ignore cancellations. */
    return NULL;
  }

  /* Options */
  /*---------*/

  async command error_t CSMAControl.enableAck() {
    signal ByteRadio.setAck(TRUE);
    return SUCCESS;
  }

  async command error_t CSMAControl.disableAck() {
    signal ByteRadio.setAck(FALSE);
    return SUCCESS;
  }

  async command error_t CSMAControl.enableCCA() {
    atomic f.ccaOff = FALSE;
    return SUCCESS;
  }

  async command error_t CSMAControl.disableCCA() {
    atomic f.ccaOff = TRUE;
    return SUCCESS;
  }

  async command error_t LowPowerListening.setListeningMode(uint8_t power) {
    if (power >= CC1K_LPL_STATES)
      return FAIL;

    atomic
      {
	if (radioState != DISABLED_STATE)
	  return FAIL;
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
    if (power >= CC1K_LPL_STATES)
      return FAIL;

    atomic
      {
	lplTxPower = power;
	setPreambleLength();
      }
    return SUCCESS;
  }

  async command uint8_t LowPowerListening.getTransmitMode() {
    atomic return lplTxPower;
  }

  async command error_t LowPowerListening.setPreambleLength(uint16_t bytes) {
    signal ByteRadio.setPreambleLength(bytes);
    return SUCCESS;
  }

  async command uint16_t LowPowerListening.getPreambleLength() {
    return signal ByteRadio.getPreambleLength();
  }

  async command error_t LowPowerListening.setCheckInterval(uint16_t ms) {
    atomic sleepTime = ms;
    return SUCCESS;
  }

  async command uint16_t LowPowerListening.getCheckInterval() {
    atomic return sleepTime;
  }

  // Default MAC backoff parameters
  default async event uint16_t CSMABackoff.initial(message_t *m) { 
    // initially back off [1,32] bytes (approx 2/3 packet)
    return (call Random.rand16() & 0x1F) + 1;
  }

  default async event uint16_t CSMABackoff.congestion(message_t *m) { 
    return (call Random.rand16() & 0xF) + 1;
    //return (((call Random.rand16() & 0x3)) + 1) << 10;
  }
}
