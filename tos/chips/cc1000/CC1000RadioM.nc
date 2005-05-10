// $Id: CC1000RadioM.nc,v 1.1.2.1 2005-05-10 20:53:05 idgay Exp $

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

module CC1000RadioM {
  provides {
    interface Init;
    interface SplitControl;
    interface Send;
    interface Receive;
    interface RadioTimeStamping;
    interface CSMAControl;
    interface CSMABackoff;
    interface LowPowerListening;
  }
  uses {
    //interface PowerManagement;
    interface CC1000Control;
    interface Random;
    interface AcquireDataNow as RSSIADC;
    interface CC1000Spi;
    interface Timer<TMilli> as WakeupTimer;
    interface Timer<TMilli> as SquelchTimer;
  }
}
implementation 
{
  enum {
    DISABLED_STATE,
    IDLE_STATE,
    SYNC_STATE,
    RX_STATE,
    RECEIVED_STATE,
    SENDING_ACK,
    PRETX_STATE,
    TXPREAMBLE_STATE,
    TXSYNC_STATE,
    TXDATA_STATE,
    TXCRC_STATE,
    TXFLUSH_STATE,
    TXWAITFORACK_STATE,
    TXREADACK_STATE,
    TXDONE_STATE,
    POWERDOWN_STATE,
    PULSECHECK_STATE
  };

  enum {
    SYNC_BYTE1 =	0x33,
    SYNC_BYTE2 =	0xcc,
    SYNC_WORD =		SYNC_BYTE1 << 8 | SYNC_BYTE2,
    ACK_BYTE1 =		0xba,
    ACK_BYTE2 =		0x83,
    ACK_WORD = 		ACK_BYTE1 << 8 | ACK_BYTE2,
    ACK_LENGTH =	16,
    MAX_ACK_WAIT =	18,
    TIME_AFTER_CHECK =  30,
  };

  uint8_t radioState = DISABLED_STATE;
  struct {
    uint8_t ack : 1;
    uint8_t ccaOff : 1;
    uint8_t invert : 1;
    uint8_t txPending : 1;
    uint8_t txBusy : 1;
  } f; // f for flags
  uint16_t count;
  uint8_t clearCount;
  uint16_t runningCrc;

  uint16_t rxShiftBuf;
  uint8_t rxBitOffset;
  message_t rxBuf;
  message_t *rxBufPtr = &rxBuf;

  uint16_t preambleLength;
  int16_t macDelay;
  message_t *txBufPtr;
  uint8_t nextTxByte;

  uint8_t lplTxPower, lplRxPower;
  uint16_t sleepTime;

  uint16_t clearThreshold = CC1K_SquelchInit;
  uint16_t rssiForSquelch;
  uint16_t squelchTable[CC1K_SquelchTableSize];
  uint8_t squelchIndex, squelchCount;

  const_uint8_t ackCode[5] = { 0xab, ACK_BYTE1, ACK_BYTE2, 0xaa, 0xaa };

  void cancelRssi();
  void adjustSquelch(uint16_t data);
  void startSquelchTimer();
  void checkChannel(uint16_t data);
  void pulseCheck(uint16_t data);
  void pulseFail(uint16_t data);
  void noiseFloor(uint16_t data);

#ifdef UNREACHABLE
  /* We only call this from signalPacketReceived, and a successful post
     of that enters the received state, which cancels RSSI */
#define enterIdleStateRssi enterIdleState

  void enterIdleState() {
    cancelRssi();
    radioState = IDLE_STATE;
    count = 0;
  }
#else
  void enterIdleStateRssi() {
    radioState = IDLE_STATE;
    count = 0;
  }

  void enterIdleState() {
    cancelRssi();
    enterIdleStateRssi();
  }
#endif

  void enterDisabledState() {
    cancelRssi();
    radioState = DISABLED_STATE;
  }

  void enterPowerDownState() {
    cancelRssi();
    radioState = POWERDOWN_STATE;
  }

  void enterPulseCheckState() {
    radioState = PULSECHECK_STATE;
    count = 0;
  }

  void enterSyncState() {
    cancelRssi();
    radioState = SYNC_STATE;
    count = 0;
  }

  void enterRxState() {
    cancelRssi();
    radioState = RX_STATE;
    rxBufPtr->header.length = sizeof rxBufPtr->data;
    count = 0;
    runningCrc = 0;
  }

  void enterReceivedState() {
    cancelRssi();
    radioState = RECEIVED_STATE;
  }

  void enterAckState() {
    cancelRssi();
    radioState = SENDING_ACK;
    count = 0;
  }

  void enterPreTxState() {
    cancelRssi();
    radioState = PRETX_STATE;
    count = clearCount = 0;
  }

  void enterTxPreambleState() {
    radioState = TXPREAMBLE_STATE;
    count = 0;
    runningCrc = 0;
    nextTxByte = 0xaa;
  }

  void enterTxSyncState() {
    radioState = TXSYNC_STATE;
  }

  void enterTxDataState() {
    radioState = TXDATA_STATE;
    // The count increment happens before the first byte is read from the
    // packet, so we initialise count to -1 to compensate.
    count = -1; 
  }

  void enterTxCrcState() {
    radioState = TXCRC_STATE;
  }
    
  void enterTxFlushState() {
    radioState = TXFLUSH_STATE;
    count = 0;
  }
    
  void enterTxWaitForAckState() {
    radioState = TXWAITFORACK_STATE;
    count = 0;
  }
    
  void enterTxReadAckState() {
    radioState = TXREADACK_STATE;
    rxShiftBuf = 0;
    count = 0;
  }
    
  void enterTxDoneState() {
    radioState = TXDONE_STATE;
  }

  /* RSSI fun. It's used for lots of things, and a request to read it
     for one purpose may have to be discarded if conditions change. For
     example, if we've initiated a noise-floor measure, but start 
     receiving a packet, we have to:
     - cancel the noise-floor measure (we don't know if the value will
       reflect the received packet or the previous idle state)
     - start an RSSI measurement so that we can report signal strength
       to the application
  */

  enum { /* The reasons for requesting RSSI */
    RSSI_IDLE, // no current measurement
    RSSI_CANCELLED, // an abandoned measurement
    RSSI_RX, // RSSI indication in received packets
    RSSI_NOISE_FLOOR, // RSSI for noise-floor estimation
    RSSI_CHECK_CHANNEL, // for checking whether the channel is clear
    RSSI_PULSE_CHECK, // low-power-listening channel check
    RSSI_PULSE_FAIL, // we misjudged packet presence. adjust noise floor before
     		     // going back to sleep.
  };
  uint8_t currentRssiOp;
  uint8_t nextRssiOp;

  void cancelRssi() {
    if (currentRssiOp != RSSI_IDLE)
      currentRssiOp = RSSI_CANCELLED;
  }

  void startRssi() {
    if (!call RSSIADC.getData())
      // XXX. we have a problem
      ;
  }

  void requestRssi(uint8_t request) {
    if (currentRssiOp == RSSI_IDLE)
      {
	currentRssiOp = request;
	startRssi();
      }
    else // We should only come here with currentRssiOp = RSSI_CANCELLED
      nextRssiOp = request;
  }

#if 0
  struct {
    uint8_t radioState;
    uint16_t rssi;
  } fun[64];
  uint8_t pos;
  uint16_t waited;
#endif

  async event void RSSIADC.dataReady(uint16_t data) {
    atomic
      {
	uint8_t op = currentRssiOp;

	/* The code assumes that RSSI measurements are 10-bits 
	   (legacy effect) */
	data >>= 6;

	if (nextRssiOp != RSSI_IDLE)
	  {
	    currentRssiOp = nextRssiOp;
	    nextRssiOp = RSSI_IDLE;
	    startRssi();
	  }
	else
	  currentRssiOp = RSSI_IDLE;

	switch (op)
	  {
	  case RSSI_CHECK_CHANNEL: checkChannel(data); break;
	  case RSSI_PULSE_CHECK: pulseCheck(data); break;
	  case RSSI_RX: rxBufPtr->metadata.strength = data; break;
	  case RSSI_NOISE_FLOOR: noiseFloor(data); break;
	  case RSSI_PULSE_FAIL: pulseFail(data); break;
	  }
      }
  }

  event void RSSIADC.error(uint16_t info) {
    // XXX
  }

  /* Low-power listening stuff */
  /*---------------------------*/
  void setPreambleLength() {
    preambleLength =
      (uint16_t)read_uint8_t(&CC1K_LPL_PreambleLength[lplTxPower * 2]) << 8
      | read_uint8_t(&CC1K_LPL_PreambleLength[lplTxPower * 2 + 1]);
  }

  void setSleepTime() {
    sleepTime =
      (uint16_t)read_uint8_t(&CC1K_LPL_SleepTime[lplRxPower *2 ]) << 8 |
      read_uint8_t(&CC1K_LPL_SleepTime[lplRxPower * 2 + 1]);
  }

  task void sendWakeupTask() {
    atomic
      if (radioState != IDLE_STATE)
	return;

    call CC1000Control.on();
    //uwait(2000);
    call CC1000Control.biasOn();
    uwait(200);
    call CC1000Control.rxMode();
    call CC1000Spi.rxMode();
    startSquelchTimer();
    call CC1000Spi.enableIntr();
  }

  /* Prepare to send when currently in low-power listen mode (i.e., 
     PULSECHECK or POWERDOWN) */
  void sendWakeup() {
    enterIdleState();
    call WakeupTimer.stop();
    if (post sendWakeupTask() != SUCCESS)
      ; // XXX. Hmm
  }

  event void WakeupTimer.fired(uint32_t when, uint32_t numMissed) {
    atomic 
      {
	if (lplRxPower == 0)
	  return;

	switch (radioState)
	  {
	  case IDLE_STATE:
	    if (!f.txPending)
	      requestRssi(RSSI_PULSE_FAIL);
	    call WakeupTimer.startOneShotNow(sleepTime);
	    break;

	  case POWERDOWN_STATE:
#ifndef UNREACHABLE
	    if (f.txPending)
	      sendWakeup();
	    else
#endif
	      {
		enterPulseCheckState();
		call CC1000Control.biasOn();
		call WakeupTimer.startOneShotNow(1);
	      }
	    break;

	  case PULSECHECK_STATE:
	    call CC1000Control.rxMode();
	    uwait(35);
	    requestRssi(RSSI_PULSE_CHECK);
	    uwait(80);
	    //call CC1000Control.biasOn();
	    //call CC1000StdControl.stop();
	    break;

	  default:
	    call WakeupTimer.startOneShotNow(5);
	    break;
	  }
      }
  }

  task void idleTimerTask() {
    startSquelchTimer();
    call WakeupTimer.startOneShotNow(TIME_AFTER_CHECK);
  }

  task void adjustSquelchAndStop() {
    uint16_t squelchData;

    atomic
      {
	squelchData = rssiForSquelch;
	if (f.txPending)
	  {
	    if (radioState == PULSECHECK_STATE)
	      sendWakeup();
	  }
	else if ((radioState == IDLE_STATE && lplRxPower > 0) ||
		 radioState == PULSECHECK_STATE)
	  {
	    enterPowerDownState();
	    call CC1000Spi.disableIntr();
	    call CC1000Control.off();
	    call WakeupTimer.startOneShotNow(sleepTime);
	  }
      }
    adjustSquelch(squelchData);
  }

  task void justStop() {
    atomic
      {
	if (f.txPending)
	  {
	    if (radioState == PULSECHECK_STATE)
	      sendWakeup();
	  }
	else if ((radioState == IDLE_STATE && lplRxPower > 0) ||
		 radioState == PULSECHECK_STATE)
	  {
	    enterPowerDownState();
	    call CC1000Spi.disableIntr();
	    call CC1000Control.off();
	    call WakeupTimer.startOneShotNow(sleepTime);
	  }
      }
  }

  void pulseCheck(uint16_t data) {
    //if(data > clearThreshold - CC1K_SquelchBuffer)
    if (data > clearThreshold - (clearThreshold >> 2))
      {
	// don't be too agressive (ignore really quiet thresholds).
	if (data < clearThreshold + (clearThreshold >> 3))
	  {
	    // adjust the noise floor level, go back to sleep.
	    rssiForSquelch = data;
	    if (post adjustSquelchAndStop() != SUCCESS)
	      ; // XXX.
	  }
	else
	  post justStop();
	
      }
    else if (count++ > 5)
      {
	//go to the idle state since no outliers were found
	enterIdleState();
	call CC1000Control.rxMode();
	call CC1000Spi.rxMode();     // SPI to miso
	call CC1000Spi.enableIntr(); // enable spi interrupt
	post idleTimerTask();
      }
    else
      {
	//call CC1000Control.rxMode();
	//uwait(35);
	requestRssi(RSSI_PULSE_CHECK);
	uwait(80);
	//call CC1000Control.biasOn();
	//call CC1000StdControl.stop();
      }
  }

  void pulseFail(uint16_t data) {
    rssiForSquelch = data;
    if (post adjustSquelchAndStop() != SUCCESS)
      ; // XXX.
  }
  


  command error_t Init.init() {
    uint8_t i;

    call CC1000Spi.initSlave(); // set spi bus to slave mode
    call CC1000Control.init();
    call CC1000Control.selectLock(0x9);		// Select MANCHESTER VIOLATION
    if (call CC1000Control.getLOStatus())
      atomic f.invert = TRUE;

    for (i = 0; i < CC1K_SquelchTableSize; i++)
      squelchTable[i] = CC1K_SquelchInit;

    return SUCCESS;
  }

  task void startDone() {
    signal SplitControl.startDone(SUCCESS);
  }

  command error_t SplitControl.start() {
    atomic 
      if (radioState == DISABLED_STATE)
	{
	  enterIdleState();
	  f.txPending = f.txBusy = FALSE;
	  setPreambleLength();
	  setSleepTime();
	  // set a time to start sleeping after measuring the noise floor
	  if (lplRxPower > 0)
	    call WakeupTimer.startOneShotNow(CC1K_SquelchIntervalSlow);
	}
      else
	return SUCCESS;

    call CC1000Control.on();
    //uwait(2000);
    call CC1000Control.biasOn();
    uwait(200);
    call CC1000Spi.rxMode();
    call CC1000Control.rxMode();
    startSquelchTimer();
    call CC1000Spi.enableIntr();

    if (post startDone() != SUCCESS)
      ; // XXX.

    return SUCCESS;
  }

  task void stopDone() {
    signal SplitControl.stopDone(SUCCESS);
  }

  command error_t SplitControl.stop() {
    atomic 
      {
	enterDisabledState();
	call CC1000Control.off();
	call CC1000Spi.disableIntr();
      }
    call SquelchTimer.stop();
    call WakeupTimer.stop();
    if (post stopDone() != SUCCESS)
      ; // XXX.
    return SUCCESS;
  }

  command error_t Send.send(message_t *msg, uint8_t len) {
    atomic
      {
	if (f.txBusy)
	  return FAIL;

	f.txBusy = TRUE;
	msg->header.length = len; //XXX???
	txBufPtr = msg;

	if (!f.ccaOff)
	  macDelay = signal CSMABackoff.initial(msg);
	else
	  macDelay = 0;
	f.txPending = TRUE;

	if (radioState == POWERDOWN_STATE)
	  sendWakeup();

#if 0
	waited = 0;
	call Leds.redOn();
#endif
      }

    return SUCCESS;
  }

  command error_t Send.cancel(message_t *msg) {
    /* We simply ignore cancellations. */
    return FAIL;
  }

  async command message_t* CSMAControl.HaltTx() {
    /* We simply ignore cancellations. */
    return NULL;
  }

  task void signalPacketSent() {
    message_t *pBuf;

    atomic
      {
	if (radioState == DISABLED_STATE)
	  return;

	pBuf = txBufPtr;
	if (lplRxPower > 0)
	  call WakeupTimer.startOneShotNow(CC1K_LPL_PACKET_TIME);
	f.txBusy = FALSE;
      }
    signal Send.sendDone(pBuf, SUCCESS);
  }

  task void signalPacketReceived() {
    message_t *pBuf;

    atomic
      {
	if (radioState != RECEIVED_STATE)
	  return;

	pBuf = rxBufPtr;
      }
    pBuf = signal Receive.receive(pBuf, pBuf, pBuf->header.length);
    atomic
      {
	if (pBuf) 
	  rxBufPtr = pBuf;
	/* We don't cancel any pending noise floor measurement */
	enterIdleStateRssi();
      }
  }

  void packetReceiveDone() {
    // We just drop packets which we could not send to the upper layers
    if (post signalPacketReceived() == SUCCESS)
      enterReceivedState();
    else
      enterIdleState();
    //requestRssi(RSSI_NOISE_FLOOR);
  }

  void packetReceived() {
    // Packet filtering based on bad CRC's is done at higher layers.
    // So sayeth the TOS weenies.
    rxBufPtr->footer.crc = rxBufPtr->footer.crc == runningCrc;

    if (f.ack &&
	rxBufPtr->footer.crc && rxBufPtr->header.addr == TOS_LOCAL_ADDRESS)
      {
	enterAckState();
	call CC1000Control.txMode();
	call CC1000Spi.txMode();
	call CC1000Spi.writeByte(0xaa);
      }
    else
      packetReceiveDone();
  }

  /* Basic SPI functions */

  void idleData(uint8_t in) {
    // Look for enough preamble bytes
    if (in == 0xaa || in == 0x55)
      {
	/* XXX: reset macDelay if txPending? */
	count++;
	if (count > CC1K_ValidPrecursor)
	  enterSyncState();
      }
    else if (f.txPending)
      if (macDelay <= 1)
	{
	  enterPreTxState();
	  requestRssi(RSSI_CHECK_CHANNEL);
	}
      else
	--macDelay;
  }

  void preTxData(uint8_t in) {
    // If we detect a preamble when we're trying to send, abort.
    if (in == 0xaa || in == 0x55)
      {
	macDelay = signal CSMABackoff.congestion(txBufPtr);
	enterIdleState();
	// we could set count to 1 here (one preamble byte seen).
	// count = 1;
      }
  }

  void syncData(uint8_t in) {
    // draw in the preamble bytes and look for a sync byte
    // save the data in a short with last byte received as msbyte
    //    and current byte received as the lsbyte.
    // use a bit shift compare to find the byte boundary for the sync byte
    // retain the shift value and use it to collect all of the packet data
    // check for data inversion, and restore proper polarity 
    // XXX-PB: Don't do this.

    if (in == 0xaa || in == 0x55)
      // It is actually possible to have the LAST BIT of the incoming
      // data be part of the Sync Byte.  SO, we need to store that
      // However, the next byte should definitely not have this pattern.
      // XXX-PB: Do we need to check for excessive preamble?
      rxShiftBuf = in << 8;
    else if (count++ == 0)
      rxShiftBuf |= in;
    else if (count <= 6)
      {
	// TODO: Modify to be tolerant of bad bits in the preamble...
	uint16_t tmp;
	uint8_t i;

	// bit shift the data in with previous sample to find sync
	tmp = rxShiftBuf;
	rxShiftBuf = rxShiftBuf << 8 | in;

	for(i = 0; i < 8; i++)
	  {
	    tmp <<= 1;
	    if (in & 0x80)
	      tmp  |=  0x1;
	    in <<= 1;
	    // check for sync bytes
	    if (tmp == SYNC_WORD)
	      {
		enterRxState();
		rxBitOffset = 7 - i;
		signal RadioTimeStamping.rxSFD(0, rxBufPtr);
		requestRssi(RSSI_RX);
	      }
	  }
      }
    else // We didn't find it after a reasonable number of tries, so....
      enterIdleState();
  }

  void rxData(uint8_t in) {
    uint8_t nextByte;
    uint8_t rxLength = rxBufPtr->header.length + offsetof(message_t, data);

    // Reject invalid length packets
    if (rxLength > TOSH_DATA_LENGTH + offsetof(message_t, data))
      {
	// The packet's screwed up, so just dump it
	enterIdleState();
	return;
      }

    rxShiftBuf = rxShiftBuf << 8 | in;
    nextByte = rxShiftBuf >> rxBitOffset;
    ((uint8_t *)rxBufPtr)[count++] = nextByte;

    if (count <= rxLength)
      runningCrc = crcByte(runningCrc, nextByte);

    // Jump to CRC when we reach the end of data
    if (count == rxLength)
      count = offsetof(message_t, footer.crc);

    if (count == offsetof(message_t, metadata))
      packetReceived();
  }

  void ackData(uint8_t in) {
    if (++count >= ACK_LENGTH)
      { 
	call CC1000Control.rxMode();
	call CC1000Spi.rxMode();
	packetReceiveDone();
      }
    else if (count >= ACK_LENGTH - sizeof ackCode)
      call CC1000Spi.writeByte(read_uint8_t(&ackCode[count + sizeof ackCode - ACK_LENGTH]));
  }

  void sendNextByte() {
    call CC1000Spi.writeByte(nextTxByte);
    count++;
  }

  void txPreamble() {
    sendNextByte();
    if (count >= preambleLength)
      {
	nextTxByte = SYNC_BYTE1;
	enterTxSyncState();
      }
  }

  void txSync() {
    sendNextByte();
    nextTxByte = SYNC_BYTE2;
    enterTxDataState();
    signal RadioTimeStamping.txSFD(0, txBufPtr); 
  }

  void txData() {
    sendNextByte();
    if (count < txBufPtr->header.length + sizeof txBufPtr->header)
      {
	nextTxByte = ((uint8_t *)txBufPtr)[count];
	runningCrc = crcByte(runningCrc, nextTxByte);
      }
    else
      {
	nextTxByte = runningCrc;
	enterTxCrcState();
      }
  }

  void txCrc() {
    sendNextByte();
    nextTxByte = runningCrc >> 8;
    enterTxFlushState();
  }

  void txFlush() {
    sendNextByte();
    if (count > 3)
      if (f.ack)
	enterTxWaitForAckState();
      else
	{
	  call CC1000Spi.rxMode();
	  call CC1000Control.rxMode();
	  enterTxDoneState();
	}
  }

  void txWaitForAck() {
    sendNextByte();
    if (count == 1)
      {
	call CC1000Spi.rxMode();
	call CC1000Control.rxMode();
      }
    else if (count > 3)
      enterTxReadAckState();
  }

  void txReadAck(uint8_t in) {
    uint8_t i;

    sendNextByte();

    for (i = 0; i < 8; i ++)
      {
	rxShiftBuf <<= 1;
	if (in & 0x80)
	  rxShiftBuf |=  0x1;
	in <<= 1;

	if (rxShiftBuf == ACK_WORD)
	  {
	    txBufPtr->metadata.ack = 1;
	    enterTxDoneState();
	    return;
	  }
      }
    if (count >= MAX_ACK_WAIT)
      {
	txBufPtr->metadata.ack = 0;
	enterTxDoneState();
      }
  }

  void txDone() {
    if (post signalPacketSent() == SUCCESS)
      {
	// If the post operation succeeds, goto Idle. Otherwise, we'll just
	// try the post again on the next SPI interrupt
	f.txPending = FALSE;
	enterIdleState();
	//requestRssi(RSSI_NOISE_FLOOR);
      }
  }

  async event void CC1000Spi.dataReady(uint8_t data) {
    //waited++;

    if (f.invert)
      data = ~data;

    switch (radioState)
      {
      default: break;
      case IDLE_STATE: idleData(data); break;
      case SYNC_STATE: syncData(data); break;
      case RX_STATE: rxData(data); break;
      case SENDING_ACK: ackData(data); break;
      case PRETX_STATE: preTxData(data); break;
      case TXPREAMBLE_STATE: txPreamble(); break;
      case TXSYNC_STATE: txSync(); break;
      case TXDATA_STATE: txData(); break;
      case TXCRC_STATE: txCrc(); break;
      case TXFLUSH_STATE: txFlush(); break;
      case TXWAITFORACK_STATE: txWaitForAck(); break;
      case TXREADACK_STATE: txReadAck(data); break;
      case TXDONE_STATE: txDone(); break;
      }
  }

  /* Noise floor stuff */
  /*-------------------*/

  void adjustSquelch(uint16_t data) {
    uint16_t squelchTab[CC1K_SquelchTableSize];
    uint8_t i, j, min; 
    uint32_t newThreshold;
    uint16_t min_value;

    squelchTable[squelchIndex++] = data;
    if (squelchIndex >= CC1K_SquelchTableSize)
      squelchIndex = 0;
    if (squelchCount <= CC1K_SquelchCount)
      squelchCount++;  

#if 0
    // Find 3rd highest (aka lowest signal strength) value
    memcpy(squelchTab, squelchTable, sizeof squelchTable);
    min = 0;
    for (j = 0; ; j++)
      {
	for (i = 1; i < CC1K_SquelchTableSize; i++)
	  if (squelchTab[i] > squelchTab[min])
	    min = i;
	if (j == 3)
	  break;
	squelchTab[min] = 0;
      }

    newThreshold = ((uint32_t)clearThreshold << 5) +
      ((uint32_t)squelchTab[min] << 1);
    atomic clearThreshold = newThreshold / 34;
#else
    for (i=0; i<CC1K_SquelchTableSize; i++) {
      squelchTab[(int)i] = squelchTable[(int)i];
    }

    min = 0;
//    for (j = 0; j < ((CC1K_SquelchTableSize) >> 1); j++) {
    for (j = 0; j < 3; j++) {
      for (i = 1; i < CC1K_SquelchTableSize; i++) {
        if ((squelchTab[(int)i] != 0xFFFF) && 
           ((squelchTab[(int)i] > squelchTab[(int)min]) ||
             (squelchTab[(int)min] == 0xFFFF))) {
          min = i;
        }
      }
      min_value = squelchTab[(int)min];
      squelchTab[(int)min] = 0xFFFF;
    }

    newThreshold = ((uint32_t)(clearThreshold << 5) + (uint32_t)(min_value << 1));
    atomic clearThreshold = (uint16_t)((newThreshold / 34) & 0x0FFFF);
#endif
  }

  task void adjustSquelchTask() {
    uint16_t squelchData;

    atomic squelchData = rssiForSquelch;
    adjustSquelch(squelchData);
  }

  void noiseFloor(uint16_t data) {
    rssiForSquelch = data;
    post adjustSquelchTask();
  }

#ifndef UNREACHABLE
  task void timeoutTask() {
    call WakeupTimer.stop();
    call WakeupTimer.startOneShotNow(5);
  }
#endif

  void checkChannel(uint16_t data) {
    count++;
    if (data > clearThreshold + CC1K_SquelchBuffer)
      clearCount++;
    else
      clearCount = 0;

    // if the channel is clear or CCA is disabled, GO GO GO!
    if (clearCount >= 1 || f.ccaOff)
      { 
#if 0
	if (txBufPtr->type == 0x2c)
	  *((uint16_t *)txBufPtr->data) = waited;
	call Leds.redOff();
	fun[pos].radioState = 0xfe;
	//fun[pos].rssi = clearThreshold;
#endif
	enterTxPreambleState();
	call CC1000Spi.writeByte(0xaa);
	call CC1000Control.txMode();
	call CC1000Spi.txMode();
      }
    else if (count == CC1K_MaxRSSISamples)
      {
	macDelay = signal CSMABackoff.congestion(txBufPtr);
	enterIdleState();
#ifndef UNREACHABLE
	if (lplRxPower > 0)
	  post timeoutTask();
#endif
      }
    else 
      requestRssi(RSSI_CHECK_CHANNEL);
  }

  void startSquelchTimer() {
    if (squelchCount > CC1K_SquelchCount)
      call SquelchTimer.startPeriodicNow(CC1K_SquelchIntervalSlow);
    else
      call SquelchTimer.startPeriodicNow(CC1K_SquelchIntervalFast);
  }

  event void SquelchTimer.fired(uint32_t when, uint32_t numMissed) {
    atomic
      if (radioState == IDLE_STATE)
	requestRssi(RSSI_NOISE_FLOOR);
  }

  /* Options */
  /*---------*/

  async command error_t CSMAControl.enableAck() {
    atomic f.ack = TRUE;
    return SUCCESS;
  }

  async command error_t CSMAControl.disableAck() {
    atomic f.ack = FALSE;
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
    atomic
      preambleLength = bytes;
    return SUCCESS;
  }

  async command uint16_t LowPowerListening.getPreambleLength() {
    atomic return preambleLength;
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

  // Default events for radio send/receive coordinators do nothing.
  // Be very careful using these, or you'll break the stack.
  default async event void RadioTimeStamping.txSFD(uint32_t time, message_t* msgBuff) { }
  default async event void RadioTimeStamping.rxSFD(uint32_t time, message_t* msgBuff) { }
}
