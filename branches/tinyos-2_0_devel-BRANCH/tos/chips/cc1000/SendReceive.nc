// $Id: SendReceive.nc,v 1.1.2.2 2005-06-02 23:19:36 idgay Exp $

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

module SendReceive {
  provides {
    interface Init;
    interface StdControl;
    interface Send;
    interface Receive;
    interface RadioTimeStamping;
    interface Packet;
    interface ByteRadio;
  }
  uses {
    //interface PowerManagement;
    interface CC1000Control;
    interface HPLCC1000Spi;

    interface AcquireDataNow as RssiRx;
  }
}
implementation 
{
  enum {
    INACTIVE_STATE,

    SYNC_STATE,
    RX_STATE,
    RECEIVED_STATE,
    SENDING_ACK,

    TXPREAMBLE_STATE,
    TXSYNC_STATE,
    TXDATA_STATE,
    TXCRC_STATE,
    TXFLUSH_STATE,
    TXWAITFORACK_STATE,
    TXREADACK_STATE,
    TXDONE_STATE,
  };

  enum {
    SYNC_BYTE1 =	0x33,
    SYNC_BYTE2 =	0xcc,
    SYNC_WORD =		SYNC_BYTE1 << 8 | SYNC_BYTE2,
    ACK_BYTE1 =		0xba,
    ACK_BYTE2 =		0x83,
    ACK_WORD = 		ACK_BYTE1 << 8 | ACK_BYTE2,
    ACK_LENGTH =	16,
    MAX_ACK_WAIT =	18
  };

  uint8_t radioState;
  struct {
    uint8_t ack : 1;
    uint8_t txBusy : 1;
    uint8_t invert : 1;
  } f; // f for flags
  uint16_t count;
  uint16_t runningCrc;

  uint16_t rxShiftBuf;
  uint8_t rxBitOffset;
  message_t rxBuf;
  message_t *rxBufPtr = &rxBuf;

  uint16_t preambleLength;
  message_t *txBufPtr;
  uint8_t nextTxByte;

  const_uint8_t ackCode[5] = { 0xab, ACK_BYTE1, ACK_BYTE2, 0xaa, 0xaa };

  void enterInactiveState() {
    radioState = INACTIVE_STATE;
  }

  void enterSyncState() {
    radioState = SYNC_STATE;
    count = 0;
  }

  void enterRxState() {
    radioState = RX_STATE;
    rxBufPtr->header.length = sizeof rxBufPtr->data;
    count = 0;
    runningCrc = 0;
  }

  void enterReceivedState() {
    radioState = RECEIVED_STATE;
  }

  void enterAckState() {
    radioState = SENDING_ACK;
    count = 0;
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

  command error_t Init.init() {
    call HPLCC1000Spi.initSlave();
    return SUCCESS;
  }

  command error_t StdControl.start() {
    atomic 
      {
	f.txBusy = FALSE;
	f.invert = call CC1000Control.getLOStatus();
      }
    return SUCCESS;
  }

  command error_t StdControl.stop() {
    atomic enterInactiveState();
    return SUCCESS;
  }

  command error_t Send.send(message_t *msg, uint8_t len) {
    atomic
      {
	if (f.txBusy)
	  return FAIL;

	f.txBusy = TRUE;
	msg->header.length = len;
	txBufPtr = msg;
      }
    signal ByteRadio.rts();

    return SUCCESS;
  }

  async command void ByteRadio.cts() {
    enterTxPreambleState();
    call HPLCC1000Spi.writeByte(0xaa);
    call CC1000Control.txMode();
    call HPLCC1000Spi.txMode();
  }

  command error_t Send.cancel(message_t *msg) {
    /* We simply ignore cancellations. */
    return FAIL;
  }

  task void signalPacketSent() {
    message_t *pBuf;

    atomic
      {
	pBuf = txBufPtr;
	f.txBusy = FALSE;
	enterInactiveState();
      }
    signal Send.sendDone(pBuf, SUCCESS);
  }

  void sendNextByte() {
    call HPLCC1000Spi.writeByte(nextTxByte);
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
	  call HPLCC1000Spi.rxMode();
	  call CC1000Control.rxMode();
	  enterTxDoneState();
	}
  }

  void txWaitForAck() {
    sendNextByte();
    if (count == 1)
      {
	call HPLCC1000Spi.rxMode();
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
    post signalPacketSent();
    signal ByteRadio.sendDone();
  }

  /* Receive */
  /* ------- */

  async command void ByteRadio.cd() {
    enterSyncState();
  }

  task void signalPacketReceived() {
    message_t *pBuf;

    atomic
      {
	if (radioState != RECEIVED_STATE)
	  return;

	pBuf = rxBufPtr;
      }
    pBuf = signal Receive.receive(pBuf, pBuf->data, pBuf->header.length);
    atomic
      {
	if (pBuf) 
	  rxBufPtr = pBuf;
	enterInactiveState();
	signal ByteRadio.rxDone();
      }
  }

  void packetReceiveDone() {
    post signalPacketReceived();
    enterReceivedState();
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
	call HPLCC1000Spi.txMode();
	call HPLCC1000Spi.writeByte(0xaa);
      }
    else
      packetReceiveDone();
  }

  /* Basic SPI functions */

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
		call RssiRx.getData();
	      }
	  }
      }
    else // We didn't find it after a reasonable number of tries, so....
      {
	enterInactiveState();
	signal ByteRadio.rxAborted();
      }
  }

  async event void RssiRx.dataReady(uint16_t data) {
    rxBufPtr->metadata.strength = data;
  }

  event void RssiRx.error(uint16_t info) {
    rxBufPtr->metadata.strength = 0;
  }

  void rxData(uint8_t in) {
    uint8_t nextByte;
    uint8_t rxLength = rxBufPtr->header.length + offsetof(message_t, data);

    // Reject invalid length packets
    if (rxLength > TOSH_DATA_LENGTH + offsetof(message_t, data))
      {
	// The packet's screwed up, so just dump it
	enterInactiveState();
	signal ByteRadio.rxDone();
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
	call HPLCC1000Spi.rxMode();
	packetReceiveDone();
      }
    else if (count >= ACK_LENGTH - sizeof ackCode)
      call HPLCC1000Spi.writeByte(read_uint8_t(&ackCode[count + sizeof ackCode - ACK_LENGTH]));
  }

  async event void HPLCC1000Spi.dataReady(uint8_t data) {
    if (f.invert)
      data = ~data;

    switch (radioState)
      {
      default: break;
      case TXPREAMBLE_STATE: txPreamble(); break;
      case TXSYNC_STATE: txSync(); break;
      case TXDATA_STATE: txData(); break;
      case TXCRC_STATE: txCrc(); break;
      case TXFLUSH_STATE: txFlush(); break;
      case TXWAITFORACK_STATE: txWaitForAck(); break;
      case TXREADACK_STATE: txReadAck(data); break;
      case TXDONE_STATE: txDone(); break;

      case SYNC_STATE: syncData(data); break;
      case RX_STATE: rxData(data); break;
      case SENDING_ACK: ackData(data); break;
      }
  }

  /* Options */
  /*---------*/

  async command void ByteRadio.setAck(bool on) {
    atomic f.ack = on;
  }

  async command void ByteRadio.setPreambleLength(uint16_t bytes) {
    atomic preambleLength = bytes;
  }

  async command uint16_t ByteRadio.getPreambleLength() {
    atomic return preambleLength;
  }

  command void Packet.clear(message_t* msg) {
    memset(msg, 0, sizeof(message_t));
  }

  command uint8_t Packet.payloadLength(message_t* msg) {
    return msg->header.length;
  }
 
  command uint8_t Packet.maxPayloadLength() {
    return TOSH_DATA_LENGTH;
  }

  command void* Packet.getPayload(message_t* msg, uint8_t* len) {
    if (len != NULL) {
      *len = msg->header.length;
    }
    return (void*)msg->data;
  }
  // Default events for radio send/receive coordinators do nothing.
  // Be very careful using these, or you'll break the stack.
  default async event void RadioTimeStamping.txSFD(uint32_t time, message_t* msgBuff) { }
  default async event void RadioTimeStamping.rxSFD(uint32_t time, message_t* msgBuff) { }
}
