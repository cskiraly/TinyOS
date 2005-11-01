// $Id: BlockStorageM.nc,v 1.1.2.4 2005-07-19 23:13:31 jwhui Exp $

/*									tab:2
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
    interface SectorStorage[blockstorage_t blockId];
    interface Leds;
    interface Mount as ActualMount[blockstorage_t blockId];
    interface StorageManager[blockstorage_t blockId];
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

  uint8_t state;
  uint8_t client;

  block_addr_t rwAddr, rwLen;
  void* rwBuf;
  uint16_t crcScratch;

  command result_t Mount.mount[blockstorage_t blockId](volume_id_t id) {
    return call ActualMount.mount[blockId](id);
  }

  event void ActualMount.mountDone[blockstorage_t blockId](storage_result_t result, volume_id_t id) {
    signal Mount.mountDone[blockId](result, id);
  }

  void signalDone(storage_result_t result) {
    uint8_t tmpState = state;
    state = S_IDLE;
    switch(tmpState) {
    case S_WRITE: signal BlockWrite.writeDone[client](result, rwAddr, rwBuf, rwLen); break;
    case S_ERASE: signal BlockWrite.eraseDone[client](result); break;
    case S_COMMIT: signal BlockWrite.commitDone[client](result); break;
    case S_READ: signal BlockRead.readDone[client](result, rwAddr, rwBuf, rwLen); break;
    case S_VERIFY: signal BlockRead.verifyDone[client](result); break;
    case S_CRC: signal BlockRead.computeCrcDone[client](result, crcScratch, rwAddr, rwLen); break;
    }
  }

  task void signalDoneTask() {
    signalDone(STORAGE_OK);
  }

  result_t newRequest(uint8_t newState, blockstorage_t blockId, 
		      block_addr_t addr, void* buf, block_addr_t len) {

    result_t result = FAIL;

    if (state != S_IDLE)
      return FAIL;

    client = blockId;

    rwAddr = addr;
    rwBuf = buf;
    rwLen = len;

    switch(newState) {
    case S_READ:
      result = call SectorStorage.read[blockId](rwAddr, rwBuf, rwLen);
      break;
    case S_CRC:
      result = call SectorStorage.computeCrc[blockId](&crcScratch, 0, rwAddr, rwLen);
      break;
    case S_VERIFY:
      break;
    case S_WRITE:
      result = call SectorStorage.write[blockId](rwAddr, rwBuf, rwLen);
      break;
    case S_ERASE:
      result = call SectorStorage.erase[blockId](0, call StorageManager.getVolumeSize[blockId]());
      break;
    case S_COMMIT:
      result = SUCCESS;
      break;
    }
    
    if (newState == S_READ || newState == S_CRC || 
	newState == S_VERIFY || newState == S_COMMIT) {
      if (result == SUCCESS) 
	result = post signalDoneTask();
    }
    
    if (result == SUCCESS)
      state = newState;

    return result;

  }
  
  command uint32_t BlockRead.getSize[blockstorage_t blockId]() {
    return call StorageManager.getVolumeSize[blockId]();
  }

  command result_t BlockRead.read[blockstorage_t blockId](block_addr_t addr, void* buf, block_addr_t len) {
    return newRequest(S_READ, blockId, addr, buf, len);
  }

  command result_t BlockRead.verify[blockstorage_t blockId]() {
    return newRequest(S_VERIFY, blockId, 0, NULL, 0);
  }

  command result_t BlockRead.computeCrc[blockstorage_t blockId](block_addr_t addr, block_addr_t len) {
    return newRequest(S_CRC, blockId, addr, NULL, len);
  }

  command result_t BlockWrite.erase[blockstorage_t blockId]() {
    return newRequest(S_ERASE, blockId, 0, NULL, 0);
  }

  command result_t BlockWrite.write[blockstorage_t blockId](block_addr_t addr, void* buf, block_addr_t len) {
    return newRequest(S_WRITE, blockId, addr, buf, len);
  }
  
  command result_t BlockWrite.commit[blockstorage_t blockId]() {
    return newRequest(S_COMMIT, blockId, 0, NULL, 0);
  }
  
  event void SectorStorage.writeDone[blockstorage_t blockId](storage_result_t result) {
    signalDone(result);
  }
  
  event void SectorStorage.eraseDone[blockstorage_t blockId](storage_result_t result) {
    signalDone(result);
  }

  default command result_t ActualMount.mount[blockstorage_t blockId](volume_id_t id) { return FAIL; }
  default command result_t SectorStorage.read[blockstorage_t blockId](stm25p_addr_t addr, void* data, stm25p_addr_t len) { return FAIL; }
  default command result_t SectorStorage.write[blockstorage_t blockId](stm25p_addr_t addr, void* data, stm25p_addr_t len) { return FAIL; }
  default command result_t SectorStorage.erase[blockstorage_t blockId](stm25p_addr_t addr, stm25p_addr_t len) { return FAIL; }
  default command result_t SectorStorage.computeCrc[blockstorage_t blockId](uint16_t* crcResult, uint16_t crc, stm25p_addr_t addr, stm25p_addr_t len) { return FAIL; }
  default command stm25p_addr_t StorageManager.getVolumeSize[blockstorage_t blockId]() { return 0; }

  default event void BlockWrite.writeDone[blockstorage_t blockId](storage_result_t result, block_addr_t addr, void* buf, block_addr_t len) { ; }
  default event void BlockWrite.eraseDone[blockstorage_t blockId](storage_result_t result) { ; }
  default event void BlockWrite.commitDone[blockstorage_t blockId](storage_result_t result) { ; }
  default event void BlockRead.readDone[blockstorage_t blockId](storage_result_t result, block_addr_t addr, void* buf, block_addr_t len) { ; }
  default event void BlockRead.verifyDone[blockstorage_t blockId](storage_result_t result) { ; }
  default event void BlockRead.computeCrcDone[blockstorage_t blockId](storage_result_t result, uint16_t crcResult, block_addr_t addr, block_addr_t len) { ; }

  default event void Mount.mountDone[blockstorage_t blockId](storage_result_t result, volume_id_t id) { ; }

}
