// $Id: BlockStorageM.nc,v 1.1.2.1 2005-02-09 01:45:52 jwhui Exp $

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
 */

module BlockStorageM {
  provides {
    interface Mount[blockstorage_t blockId];
    interface BlockRead[blockstorage_t blockId];
    interface BlockWrite[blockstorage_t blockId];
  }
  uses {
    interface HALSTM25P[blockstorage_t blockId];
    interface Mount as ActualMount[blockstorage_t blockId];
  }
}

implementation {

  enum {
    S_IDLE,
    S_WRITE,
    S_ERASE,
    S_COMMIT,
    S_READ,
    S_VERIFY,
    S_CRC,
  };

  uint8_t baseAddr;

  uint8_t state;
  uint8_t client;

  uint8_t* bufPtr;
  block_addr_t curAddr;
  block_addr_t bytesRemaining;
  uint16_t crc;

  void actualSignal(result_t result) {

    uint8_t tmpState = state;

    state = S_IDLE;

    switch(tmpState) {
    case S_READ: signal BlockRead.readDone[client](result); break;
    case S_WRITE: signal BlockWrite.writeDone[client](result); break;
    case S_ERASE: signal BlockWrite.eraseDone[client](result); break;
    case S_CRC: signal BlockRead.computeCrcDone[client](result, crc); break;
    }

  }

  task void signalSuccess() { actualSignal(SUCCESS); }
  
  task void signalFail() { actualSignal(FAIL); }

  void signalDone(result_t result) {
    if (result == SUCCESS)
      post signalSuccess();
    else
      post signalFail();
  }

  command result_t Mount.mount[blockstorage_t blockId](volume_id_t id) {
    return call ActualMount.mount[blockId](id);
  }

  event void ActualMount.mountDone[blockstorage_t blockId](storage_result_t result, volume_id_t id) {
    signal Mount.mountDone[blockId](result, id);
  }

  bool admitRequest(blockstorage_t blockId) {
    if (state != S_IDLE)
      return FALSE;
    client = blockId;
    return TRUE;
  }

  block_addr_t calcNumBytes() {

    block_addr_t pageOffset = curAddr % (block_addr_t)STM25P_PAGE_SIZE;
    block_addr_t numBytes = STM25P_PAGE_SIZE - pageOffset;

    if (bytesRemaining < numBytes)
      numBytes = bytesRemaining;

    return numBytes;

  }

  command result_t BlockWrite.write[blockstorage_t blockId](block_addr_t addr, uint8_t* buf, block_addr_t len) {

    if (admitRequest(blockId) == FAIL)
      return FAIL;

    curAddr = addr;
    bufPtr = buf;
    bytesRemaining = len;

    state = S_WRITE;

    if (call HALSTM25P.pageProgram[blockId](addr, buf, calcNumBytes()) == FAIL) {
      state = S_IDLE;
      return FAIL;
    }
    
    return SUCCESS;

  }

  command result_t BlockWrite.erase[blockstorage_t blockId]() {

    if (admitRequest(blockId) == FAIL)
      return FAIL;

    state = S_ERASE;

    if (call HALSTM25P.sectorErase[blockId](0) == FAIL) {
      state = S_IDLE;
      return FAIL;
    }

    return SUCCESS;

  }

  command result_t BlockWrite.commit[blockstorage_t blockId]() {

    if (admitRequest(blockId) == FAIL)
      return FAIL;

    state = S_COMMIT;

    state = S_IDLE;

    return SUCCESS;

  }

  command result_t BlockRead.read[blockstorage_t blockId](block_addr_t addr, uint8_t* buf, block_addr_t len) {

    if (admitRequest(blockId) == FAIL)
      return FAIL;

    state = S_READ;

    if (call HALSTM25P.read[blockId](addr, buf, len) == FAIL) {
      state = S_IDLE;
      return FAIL;
    }

    return SUCCESS;

  }

  command result_t BlockRead.verify[blockstorage_t blockId]() {
    if (admitRequest(blockId) == FAIL)
      return FAIL;
    state = S_VERIFY;
    state = S_IDLE;
    return SUCCESS;
  }

  command result_t BlockRead.computeCrc[blockstorage_t blockId](block_addr_t addr, block_addr_t len) {

    if (admitRequest(blockId) == FAIL)
      return FAIL;

    state = S_CRC;

    if (call HALSTM25P.computeCrc[blockId](addr, len) == FAIL) {
      state = S_IDLE;
      return FAIL;
    }

    return SUCCESS;

  }

  event void HALSTM25P.readDone[blockstorage_t blockId](result_t result) {
    signalDone(result);
  }

  event void HALSTM25P.pageProgramDone[blockstorage_t blockId](result_t result) {

    block_addr_t lastBytes = calcNumBytes();

    if (bytesRemaining <= lastBytes) {
      signalDone(SUCCESS);
      return;
    }
    else {
      curAddr += lastBytes;
      bufPtr += lastBytes;
      bytesRemaining -= lastBytes;
    }

    if (call HALSTM25P.pageProgram[blockId](curAddr, bufPtr, calcNumBytes()) == FAIL)
      signalDone(FAIL);

    return;

  }

  event void HALSTM25P.sectorEraseDone[blockstorage_t blockId](result_t result) {
    signalDone(result);
    return;
  }

  event void HALSTM25P.bulkEraseDone[blockstorage_t blockId](result_t result) { 
    return;
  }

  event void HALSTM25P.writeSRDone[blockstorage_t blockId](result_t result) {
    return;
  }

  event void HALSTM25P.computeCrcDone[blockstorage_t blockId](result_t result, uint16_t crcResult) {
    crc = crcResult;
    signalDone(result);
    return;
  }

  default command result_t ActualMount.mount[blockstorage_t blockId](volume_id_t id) { return FAIL; }
  default command result_t HALSTM25P.read[blockstorage_t blockId](stm25p_addr_t addr, uint8_t* data, stm25p_addr_t len) { return FAIL; }
  default command result_t HALSTM25P.pageProgram[blockstorage_t blockId](stm25p_addr_t addr, uint8_t* data, stm25p_addr_t len) { return FAIL; }
  default command result_t HALSTM25P.sectorErase[blockstorage_t blockId](stm25p_addr_t addr) { return FAIL; }
  default command result_t HALSTM25P.bulkErase[blockstorage_t blockId]() { return FAIL; }
  default command result_t HALSTM25P.writeSR[blockstorage_t blockId](uint8_t value) { return FAIL; }
  default command result_t HALSTM25P.computeCrc[blockstorage_t blockId](stm25p_addr_t addr, stm25p_addr_t len) { return FAIL; }
  default command stm25p_sig_t HALSTM25P.getSignature[blockstorage_t blockId]() { return FAIL; }

  default event void BlockWrite.writeDone[blockstorage_t blockId](result_t result) { return; }
  default event void BlockWrite.eraseDone[blockstorage_t blockId](result_t result) { return; }
  default event void BlockWrite.commitDone[blockstorage_t blockId](result_t result) { return; }
  default event void BlockRead.readDone[blockstorage_t blockId](result_t result) { return; }
  default event void BlockRead.verifyDone[blockstorage_t blockId](result_t result) { return; }
  default event void BlockRead.computeCrcDone[blockstorage_t blockId](result_t result, uint16_t crcResult) { return; }

  default event void Mount.mountDone[blockstorage_t blockId](storage_result_t result, volume_id_t id) { ; }

}
