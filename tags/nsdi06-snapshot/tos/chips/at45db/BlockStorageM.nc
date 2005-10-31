// $Id: BlockStorageM.nc,v 1.1.2.1 2005-02-09 18:34:01 idgay Exp $

/*									tab:4
 * "Copyright (c) 2000-2004 The Regents of the University  of California.  
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
 */

/*
 * @author: Jonathan Hui <jwhui@cs.berkeley.edu>
 * @author: David Gay <dgay@acm.org>
 */

module BlockStorageM {
  provides {
    interface Mount[blockstorage_t blockId];
    interface BlockWrite[blockstorage_t blockId];
    interface BlockRead[blockstorage_t blockId];
  }
  uses {
    interface HALAT45DB[blockstorage_t blockId];
    interface Mount as ActualMount[blockstorage_t blockId];
  }
}
implementation 
{
  enum {
    S_IDLE,
    S_WRITE,
    S_ERASE,
    S_COMMIT, S_COMMIT2, S_COMMIT3,
    S_READ,
    S_VERIFY,
    S_CRC,
  };

  uint8_t state = S_IDLE;
  uint8_t client;

  uint8_t* bufPtr;
  block_addr_t curAddr;
  block_addr_t bytesRemaining;
  uint16_t crc;
  block_addr_t maxAddr[uniqueCount(UQ_BLOCK_STORAGE)];

  void commitSignature();
  void commitSync();

  result_t actualSignal(result_t result) {
    uint8_t tmpState = state;

    state = S_IDLE;
    switch(tmpState)
      {
      case S_READ: return signal BlockRead.readDone[client](result);
      case S_WRITE: return signal BlockWrite.writeDone[client](result);
      case S_ERASE: return signal BlockWrite.eraseDone[client](result);
      case S_CRC: return signal BlockRead.computeCrcDone[client](result, crc);
      case S_COMMIT: case S_COMMIT2: case S_COMMIT3:
	return signal BlockWrite.commitDone[client](result);
      }

    return SUCCESS;
  }

  task void signalSuccess() { actualSignal(SUCCESS); }
  
  task void signalFail() { actualSignal(FAIL); }

  void signalDone(result_t result) {
    if (result == SUCCESS)
      switch (state)
	{
	case S_COMMIT: commitSignature(); break;
	case S_COMMIT2: commitSync(); break;
	default: post signalSuccess(); break;
	}
    else
      post signalFail();
  }

  void check(result_t ok) {
    if (!ok)
      post signalFail();
  }

  bool admitRequest(uint8_t newState, uint8_t id) {
    if (state != S_IDLE)
      return FALSE;
    client = id;
    state = newState;
    return TRUE;
  }

  void calcRequest(block_addr_t addr, at45page_t *page,
		   at45pageoffset_t *offset, at45pageoffset_t *count) {
    *page = addr >> AT45_PAGE_SIZE_LOG2;
    *offset = addr & ((1 << AT45_PAGE_SIZE_LOG2) - 1);
    if (bytesRemaining < (1 << AT45_PAGE_SIZE_LOG2) - *offset)
      *count = bytesRemaining;
    else
      *count = (1 << AT45_PAGE_SIZE_LOG2) - *offset;
  }

  void continueRequest() {
    at45page_t page;
    at45pageoffset_t offset, count;
    uint8_t *buf = bufPtr;

    calcRequest(curAddr, &page, &offset, &count);
    bytesRemaining -= count;
    curAddr += count;
    bufPtr += count;

    switch (state)
      {
      case S_WRITE:
	check(call HALAT45DB.write(page, offset, buf, count));
	break;
      case S_READ:
	check(call HALAT45DB.read(page, offset, buf, count));
	break;
      case S_CRC: case S_COMMIT:
	check(call HALAT45DB.computeCrc(page, offset, count, crc));
	break;
      }
  }

  void newRequest(uint8_t newState, uint8_t id,
		  block_addr_t addr, uint8_t* buf, block_addr_t len) {
    if (admitRequest(newState, id) == FAIL)
      return FAIL;

    curAddr = addr;
    bufPtr = buf;
    bytesRemaining = len;
    crc = 0;

    continueRequest();

    return SUCCESS;
  }

  command result_t BlockWrite.write[uint8_t id](block_addr_t addr, uint8_t* buf, block_addr_t len) {
    result_t ok = newRequest(S_WRITE, addr, buf, len);

    if (ok && addr + len > maxAddr[id])
      maxAddr[id] = addr+len;

    return ok;
  }

  command result_t BlockWrite.erase[uint8_t id]() {
    if (admitRequest(S_ERASE, id) == FAIL)
      return FAIL;

    check(call HALAT45DB.erase(0, AT45_ERASE));

    return SUCCESS;
  }

  command result_t BlockWrite.commit[uint8_t id]() {
    return newRequest(S_COMMIT, 0, NULL, maxAddr[id]);
  }

  /* Called once crc computed. Write crc + signature in block 0. */
  void commitSignature() {
    static uint8_t sig[4];

    sig[0] = crc;
    sig[1] = crc >> 8;
    sig[2] = 0xb1; /* block sig: b10c */
    sig[3] = 0x0c;
    state = S_COMMIT2;
    /* Note: bytesRemaining is 0, so multipageDone will got straight to
       signalDone */
    check(call HALAT45DB.write(0, 1 << AT45_PAGE_SIZE_LOG2, sig, 4));
  }

  /* Called once signature written. Ensure writes complete. */
  void commitSunc() {
    state = S_COMMIT3;
    check(call HALAT45DB.syncAll());
  }

  command result_t BlockRead.read[uint8_t id](block_addr_t addr, uint8_t* buf, block_addr_t len) {
    return newRequest(S_READ, addr, buf, len);
  }

  command result_t BlockRead.verify[uint8_t id]() {
    return FAIL;
  }

  command result_t BlockRead.computeCrc[uint8_t id](block_addr_t addr, block_addr_t len) {
    return newRequest(S_CRC, addr, NULL, len);
  }

  result_t multipageDone(result_t result) {
    if (bytesRemaining == 0 || result == FAIL)
      signalDone(result);
    else
      continueRequest();
  }

  event result_t HALAT45DB.writeDone(result_t result) {
    return multipageDone(result);
  }

  event result_t HALAT45DB.readDone(result_t result) {
    return multipageDone(result);
  }

  event result_t HALAT45DB.computeCrcDone(result_t result, uint16_t newCrc) {
    crc = newCrc;
    return multipageDone(result);
  }

  event result_t HALAT45DB.eraseDone(result_t result) {
    signalDone(result);
    return SUCCESS;
  }

  event result_t HALAT45DB.syncDone(result_t result) {
    signalDone(result);
    return SUCCESS;
  }

  event result_t HALAT45DB.flushDone(result_t result) {
    return SUCCESS;
  }

  default event result_t BlockWrite.writeDone[uint8_t id](result_t result) { return SUCCESS; }
  default event result_t BlockWrite.eraseDone[uint8_t id](result_t result) { return SUCCESS; }
  default event result_t BlockWrite.commitDone[uint8_t id](result_t result) { return SUCCESS; }
  default event result_t BlockRead.readDone[uint8_t id](result_t result) { return SUCCESS; }
  default event result_t BlockRead.verifyDone[uint8_t id](result_t result) { return SUCCESS; }
  default event result_t BlockRead.computeCrcDone[uint8_t id](result_t result, uint16_t crcResult) { return SUCCESS; }

  command result_t Mount.mount[blockstorage_t blockId](volume_id_t id) {
    maxAddr[id] = 0;
    return call ActualMount.mount[blockId](id);
  }

  event void ActualMount.mountDone[blockstorage_t blockId](storage_result_t result, volume_id_t id) {
    return signal Mount.mountDone[blockId](result, id);
  }
}
