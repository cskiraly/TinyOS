// $Id: LogStorageM.nc,v 1.1.2.3 2005-07-11 19:18:25 jwhui Exp $

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

module LogStorageM {
  provides {
    interface Mount[logstorage_t logId];
    interface LogRead[logstorage_t logId];
    interface LogWrite[logstorage_t logId];
  }
  uses {
    interface SectorStorage[logstorage_t logId];
    interface Leds;
    interface Mount as ActualMount[logstorage_t logId];
    interface StorageManager[logstorage_t logId];
  }
}

implementation {

  enum {
    NUM_LOGS = uniqueCount("LogStorage"),
    BLOCK_SIZE = 1024,
    BLOCK_MASK = BLOCK_SIZE-1,
    INVALID_PTR = 0xffffffff,
    INVALID_HDR = 0xff,
  };

  enum {
    S_IDLE,
    S_MOUNT,
    S_READ,
    S_SEEK,
    S_ERASE,
    S_APPEND,
    S_SYNC,
  };

  enum {
    S_APPEND_IDLE,
    S_ERASE_SECTOR,
    S_WRITE_POINTER,
    S_WRITE_HEADER,
    S_WRITE_DATA,
  };

  typedef struct log_info_t {
    stm25p_addr_t curReadPtr;
    stm25p_addr_t curWritePtr;
    stm25p_addr_t volumeSize;
  } log_info_t;

  log_info_t logInfo[NUM_LOGS];
  log_info_t* log;
  logstorage_t client;

  uint8_t state, appendState;
  volume_id_t volumeId;

  void* rwData;
  log_len_t rwLen;
  uint8_t header;

  void signalDone(result_t result) {
    uint8_t tmpState = state;
    state = S_IDLE;
    switch(tmpState) {
    case S_MOUNT: signal Mount.mountDone[client](result, volumeId); break;
    case S_READ: signal LogRead.readDone[client](result, rwData, rwLen); break;
    case S_SEEK: signal LogRead.seekDone[client](result, log->curReadPtr); break;
    case S_ERASE: signal LogWrite.eraseDone[client](result); break;
    case S_APPEND: signal LogWrite.appendDone[client](result, rwData, rwLen); break;
    case S_SYNC: signal LogWrite.syncDone[client](result); break;
    }
  }

  task void signalDoneTask() {
    signalDone(STORAGE_OK);
  }

  bool admitRequest(logstorage_t logId) {
    if ( state != S_IDLE )
      return FALSE;
    log = &logInfo[logId];
    client = logId;
    return TRUE;
  }

  stm25p_addr_t toVolAddr(stm25p_addr_t addr) __attribute__ ((noinline)) {
    return addr % log->volumeSize;
  }

  command result_t Mount.mount[logstorage_t logId](volume_id_t id) {

    result_t result;

    if ( !admitRequest(logId) )
      return FAIL;

    appendState = S_APPEND_IDLE;

    result = call ActualMount.mount[logId](id);

    if ( result == SUCCESS ) {
      state = S_MOUNT;
      volumeId = id;
    }

    return result;

  }

  event void ActualMount.mountDone[logstorage_t logId](storage_result_t result, volume_id_t id) {

    stm25p_addr_t tmpReadPtr, tmpWritePtr, tmpPtr;
    stm25p_addr_t curAddr;

    if ( result != STORAGE_OK ) {
      signalDone(STORAGE_FAIL);
      return;
    }

    log->volumeSize = call StorageManager.getVolumeSize[logId]();

    tmpWritePtr = 0;
    tmpReadPtr = INVALID_PTR;

    for ( curAddr = 0; curAddr < log->volumeSize; curAddr += BLOCK_SIZE ) {
      call SectorStorage.read[logId](curAddr, &tmpPtr, sizeof(tmpPtr));

      // skip if pointer is all ones
      if ( tmpPtr == INVALID_PTR )
	continue;

      // remember smallest/largest pointer for sector
      if ( tmpPtr < tmpReadPtr )
	tmpReadPtr = tmpPtr;
      if ( tmpPtr > tmpWritePtr )
	tmpWritePtr = tmpPtr;
    }

    // log is empty, reset read pointer
    if ( tmpReadPtr == INVALID_PTR ) {
      tmpReadPtr = 0;
    }

    // log is not empty, advance write pointer to last log entry
    else {
      
      tmpWritePtr += sizeof(tmpWritePtr);
      header = 0;
      do {
	tmpWritePtr += header + sizeof(header);
	call SectorStorage.read[logId](toVolAddr(tmpWritePtr), &header, sizeof(header));
      } while ( header != INVALID_HDR );

    }

    log->curReadPtr = tmpReadPtr + sizeof(tmpReadPtr);
    log->curWritePtr = tmpWritePtr;

    signalDone(STORAGE_OK);

  }

  command result_t LogRead.read[logstorage_t logId](void* data, log_len_t len) {

    stm25p_addr_t tmpReadPtr;
    uint8_t bytesRead;

    if ( !admitRequest(logId) )
      return FAIL;

    tmpReadPtr = log->curReadPtr;

    do {

      // at beginning of log block
      if ( !((uint16_t)tmpReadPtr % BLOCK_SIZE) ) {
	if ( !( (uint16_t)tmpReadPtr + BLOCK_SIZE ) )
	  tmpReadPtr += BLOCK_SIZE;
	tmpReadPtr += sizeof(tmpReadPtr);
      }

      // don't read past end of log
      if ( tmpReadPtr >= log->curWritePtr )
	return FAIL;

      // read length of log entry
      if ( call SectorStorage.read[logId](toVolAddr(tmpReadPtr), &header, sizeof(header)) 
	   == FAIL )
	return FAIL;
      
      // skip to next log block if at end of current block
      if ( header == INVALID_HDR )
	tmpReadPtr += BLOCK_SIZE - (tmpReadPtr % BLOCK_SIZE);

    } while ( header == INVALID_HDR );
    
    tmpReadPtr += sizeof(header);
    bytesRead = ( len < header ) ? len : header;
    
    // read data
    call SectorStorage.read[logId](toVolAddr(tmpReadPtr), data, bytesRead);
    // advance to next log entry
    log->curReadPtr = tmpReadPtr + header;

    if ( !post signalDoneTask() ) 
      return FAIL;

    state = S_READ;
    rwData = data;
    rwLen = bytesRead;
    return SUCCESS;

  }
  
  command result_t LogRead.seek[logstorage_t logId](log_cookie_t cookie) {

    if ( !admitRequest(logId) )
      return FAIL;

    // make sure cookie is valid
    if ( cookie > log->curWritePtr || log->curWritePtr - cookie > log->volumeSize )
      return FAIL;
    
    log->curReadPtr = cookie;
    
    if ( !post signalDoneTask() )
      return FAIL;
    
    state = S_SEEK;
    return SUCCESS;

  }

  command log_cookie_t LogRead.currentOffset[logstorage_t logId]() {
    return logInfo[logId].curReadPtr;
  }

  command result_t LogWrite.erase[logstorage_t logId]() {

    stm25p_addr_t len;
    result_t result;

    if ( !admitRequest(logId) )
      return FAIL;

    len = call StorageManager.getVolumeSize[logId]();
    result = call SectorStorage.erase[logId](0, len);

    if ( result == SUCCESS )
      state = S_ERASE;

    return result;

  }

  result_t continueAppendOp() {

    stm25p_addr_t tmpWritePtr = log->curWritePtr;
    void* buf;
    log_len_t len;

    // if on sector boundary
    if ( appendState != S_ERASE_SECTOR && !((uint16_t)tmpWritePtr) ) {
      // check if read pointer is too far behind
      stm25p_addr_t tmpReadPtr = tmpWritePtr - log->volumeSize + STM25P_SECTOR_SIZE;
      if ( log->curReadPtr < tmpReadPtr && tmpWritePtr )
	log->curReadPtr = tmpReadPtr;
      appendState = S_ERASE_SECTOR;
      return call SectorStorage.erase[client](toVolAddr(tmpWritePtr), STM25P_SECTOR_SIZE);
    }
    
    // if on a block boundary
    else if ( !((uint16_t)tmpWritePtr % BLOCK_SIZE) ) {
      appendState = S_WRITE_POINTER;
      buf = &log->curWritePtr;
      len = sizeof(tmpWritePtr);
    }

    // write header
    else if ( appendState != S_WRITE_HEADER ) {
      appendState = S_WRITE_HEADER;
      header = rwLen;
      buf = &header;
      len = sizeof(header);
    }

    // write data
    else {
      appendState = S_WRITE_DATA;
      buf = rwData;
      len = rwLen;
    }
    
    return call SectorStorage.write[client](toVolAddr(tmpWritePtr), buf, len);
    
  }

  command result_t LogWrite.append[logstorage_t logId](void* data, log_len_t len) {

    uint16_t bytesRemaining = BLOCK_SIZE - ((uint16_t)log->curWritePtr % BLOCK_SIZE);
    result_t result;

    // XXX: do not allow appends of data chunks >= 256 bytes, this is just
    //      to keep things simple for now
    if ( !admitRequest(logId) || len >= 256 )
      return FAIL;

    // if not enough bytes are left in the current block, advance pointer
    if ( len >= bytesRemaining )
      log->curWritePtr += bytesRemaining;

    if ( !(uint16_t)( log->curWritePtr + BLOCK_SIZE ) )
      log->curWritePtr += BLOCK_SIZE;

    rwData = data;
    rwLen = len;

    result = continueAppendOp();

    if ( result == SUCCESS )
      state = S_APPEND;

    return result;

  }

  command result_t LogWrite.sync[logstorage_t logId]() {

    if ( !admitRequest(logId) || !post signalDoneTask() )
      return FAIL;

    state = S_SYNC;
    return SUCCESS;

  }

  command log_cookie_t LogWrite.currentOffset[logstorage_t logId]() {
    return logInfo[logId].curWritePtr;
  }
  
  event void SectorStorage.eraseDone[logstorage_t logId](storage_result_t result) {

    // erase command
    if ( state == S_ERASE ) {
      log->curReadPtr = sizeof(stm25p_addr_t);
      log->curWritePtr = 0;
      signalDone(result); 
    }

    // part of append command
    else if ( result == STORAGE_FAIL || continueAppendOp() == FAIL ) {
      signalDone(STORAGE_FAIL);
    }

  }

  event void SectorStorage.writeDone[logstorage_t logId](storage_result_t result) { 

    if ( result == STORAGE_FAIL )
      signalDone(STORAGE_FAIL);
    
    switch(appendState) {
    case S_WRITE_POINTER: 
      log->curWritePtr += sizeof(log->curWritePtr); 
      break;
    case S_WRITE_HEADER:
      log->curWritePtr += sizeof(header);
      break;
    case S_WRITE_DATA: 
      log->curWritePtr += rwLen; 
      signalDone(STORAGE_OK);
      return;
    }

    continueAppendOp();

  }

  default command result_t ActualMount.mount[logstorage_t logId](volume_id_t id) { return FAIL; }
  default command result_t SectorStorage.read[logstorage_t logId](stm25p_addr_t addr, void* data, stm25p_addr_t len) { return FAIL; }
  default command result_t SectorStorage.write[logstorage_t logId](stm25p_addr_t addr, void* data, stm25p_addr_t len) { return FAIL; }
  default command result_t SectorStorage.erase[logstorage_t logId](stm25p_addr_t addr, stm25p_addr_t len) { return FAIL; }
  default command result_t SectorStorage.computeCrc[logstorage_t logId](uint16_t* crcResult, uint16_t crc, stm25p_addr_t addr, stm25p_addr_t len) { return FAIL; }
  default command uint8_t StorageManager.getNumSectors[logstorage_t logId]() { return 0; }
  default command stm25p_addr_t StorageManager.getVolumeSize[logstorage_t logId]() { return STM25P_INVALID_ADDR; }

  default event void LogRead.readDone[logstorage_t logId](storage_result_t result, void* data, log_len_t numBytes) {}
  default event void LogRead.seekDone[logstorage_t logId](storage_result_t result, log_cookie_t cookie) {}
  default event void LogWrite.eraseDone[logstorage_t logId](storage_result_t result) {}
  default event void LogWrite.appendDone[logstorage_t logId](storage_result_t result, void* data, log_len_t numBytes) {}
  default event void LogWrite.syncDone[logstorage_t logId](storage_result_t result) {}

  default event void Mount.mountDone[logstorage_t logId](storage_result_t result, volume_id_t id) {}

}
