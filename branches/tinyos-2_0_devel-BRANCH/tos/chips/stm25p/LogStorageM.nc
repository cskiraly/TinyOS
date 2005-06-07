// $Id: LogStorageM.nc,v 1.1.2.1 2005-06-07 20:05:35 jwhui Exp $

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
    S_IDLE,
    S_MOUNT,
    S_ERASE,
    S_WRITE_SECTOR_HEADER,
    S_INIT_BLOCK_HEADER,
    S_COMMIT_BLOCK_HEADER,
    S_APPEND,
    S_SYNC,
    S_READ,
    S_SEEK,
  };

  struct {
    log_cookie_t curReadCookie;
    log_cookie_t curWriteCookie;
    log_block_addr_t curReadBlockLen;
    log_block_addr_t curWriteBlockPos;
  } log[uniqueCount("LogStorage")];
  
  LogSectorHeader sectorHeader;
  LogBlockHeader blockHeader;
  
  log_len_t rwLen, curLen, lastLen;
  void* rwData;
  
  uint8_t state;
  logstorage_t client;
  volume_id_t volumeId;


  void signalDone(storage_result_t result) {

    uint8_t tmpState = state;

    state = S_IDLE;

    switch(tmpState) {
    case S_MOUNT: signal Mount.mountDone[client](result, volumeId); break;
    case S_ERASE: signal LogWrite.eraseDone[client](result); break;
    case S_APPEND: signal LogWrite.appendDone[client](result, rwData, rwLen); break;
    case S_SYNC: signal LogWrite.syncDone[client](result); break;
    case S_READ: signal LogRead.readDone[client](result, rwData, rwLen); break;
    case S_SEEK: signal LogRead.seekDone[client](result, log[client].curReadCookie); break;
    }

  }

  task void signalDoneTask() {
    signalDone(STORAGE_OK);
  }

  bool admitRequest(logstorage_t logId) {
    if (state != S_IDLE)
      return FALSE;
    client = logId;
    return TRUE;
  }

  result_t advanceCookie(log_cookie_t *curCookie) {

    log_cookie_t cookie = *curCookie;
    bool advancingWriteCookie = cookie == log[client].curWriteCookie;
    uint8_t newSector;
    
    while ( advancingWriteCookie || cookie < log[client].curWriteCookie ) {

      // if at beginning of sector, advance read cookie
      if (!(cookie % STM25P_SECTOR_SIZE))
	cookie += sizeof(LogSectorHeader);
      
      // read block header
      if (call SectorStorage.read[client](cookie, &blockHeader, sizeof(blockHeader)) 
	  == FAIL)
	return FAIL;

      // take block if:
      // 1) not allocated
      // 2) block is valid
      // 3) block current being written
      if ( !(~blockHeader.flags & LOG_BLOCK_ALLOCATED)
	   || (~blockHeader.flags & LOG_BLOCK_VALID)
	   || (!advancingWriteCookie && cookie >= 
	       log[client].curWriteCookie - log[client].curWriteBlockPos) ) {
	break;
      }
      
      // advance to next log block
      newSector = (cookie >> STM25P_SECTOR_SIZE_LOG2) + 1;
      cookie += LOG_BLOCK_MAX_LENGTH;
      if (newSector == cookie >> STM25P_SECTOR_SIZE_LOG2)
	cookie = (stm25p_addr_t)newSector << STM25P_SECTOR_SIZE_LOG2;

    }

    *curCookie = cookie;

    return SUCCESS;

  }

  command result_t Mount.mount[logstorage_t logId](volume_id_t id) {
    if (admitRequest(logId) == FAIL)
      return FAIL;
    state = S_MOUNT;
    return call ActualMount.mount[logId](id);
  }

  event void ActualMount.mountDone[logstorage_t logId](storage_result_t result, volume_id_t id) {

    uint8_t numSectors = call StorageManager.getNumSectors[logId]();
    uint8_t curSector;

    volumeId = id;

    log[logId].curWriteBlockPos = log[logId].curReadBlockLen = 0;

    // find sector with smallest/largest sector header cookie
    log[logId].curWriteCookie = 0;
    log[logId].curReadCookie = LOG_MAX_COOKIE;
    
    for ( curSector = 0; curSector < numSectors; curSector++ ) {
      stm25p_addr_t curAddr = curSector * STM25P_SECTOR_SIZE;
      if (call SectorStorage.read[logId](curAddr, &sectorHeader, sizeof(sectorHeader))
	  == FAIL) {
	signalDone(STORAGE_FAIL);
	return;
      }

      // skip if sector header is all ones
      if (!~sectorHeader.cookie)
	continue;

      // remember smallest/largest sector header cookie
      if (sectorHeader.cookie < log[logId].curReadCookie)
	log[logId].curReadCookie = sectorHeader.cookie;
      if (sectorHeader.cookie > log[logId].curWriteCookie)
	log[logId].curWriteCookie = sectorHeader.cookie;
    }

    // advance curWriteCookie to last log block
    blockHeader.length = 0;
    do {
      log[logId].curWriteCookie += blockHeader.length;
      if (advanceCookie(&(log[logId].curWriteCookie)) == FAIL) {
 	signalDone(STORAGE_FAIL);
	return;
      }
    } while ( ~blockHeader.flags & LOG_BLOCK_ALLOCATED );

    signalDone(STORAGE_OK);
    
  }

  command result_t LogRead.read[logstorage_t logId](void* data, log_len_t numBytes) {

    log_len_t lastBytes;

    if ( admitRequest(logId) == FAIL )
      return FAIL;

    while ( numBytes > 0 ) {

      // if at beginning of block, read block header
      if ( log[logId].curReadBlockLen == 0 ) {

	if (advanceCookie(&(log[logId].curReadCookie)) == FAIL)
	  return FAIL;

	// if block header is valid
	if ( ~blockHeader.flags & LOG_BLOCK_VALID ) {
	  log[logId].curReadBlockLen = blockHeader.length - sizeof(LogBlockHeader);
	  log[logId].curReadCookie += sizeof(LogBlockHeader);
	}
	// if block header is for block that is currently being written
	else if ( log[logId].curReadCookie >= 
		  log[logId].curWriteCookie - log[logId].curWriteBlockPos ) {
	  log[logId].curReadBlockLen = log[logId].curWriteBlockPos - sizeof(LogBlockHeader);
	  log[logId].curReadCookie += sizeof(LogBlockHeader);
	}

      }

      // make sure we're not reading off the end of the log
      if (log[logId].curReadCookie + numBytes > log[logId].curWriteCookie)
	return FAIL;

      lastBytes = numBytes;

      // check for end of log block
      if ( log[logId].curReadBlockLen < lastBytes )
	lastBytes = log[logId].curReadBlockLen;

      // read data
      if (call SectorStorage.read[logId](log[logId].curReadCookie, data, lastBytes) == FAIL)
	return FAIL;
      
      // advance pointers
      log[logId].curReadCookie += lastBytes;
      data += lastBytes;
      log[logId].curReadBlockLen -= lastBytes;
      numBytes -= lastBytes;

    }

    if (post signalDoneTask() == SUCCESS) {
      state = S_READ;
      return SUCCESS;
    }

    return FAIL;

  }

  command result_t LogRead.seek[logstorage_t logId](log_cookie_t cookie) {
    
    log_cookie_t newReadCookie;
    uint8_t numSectors = call StorageManager.getNumSectors[logId]();
    uint8_t curSector;

    if (admitRequest(logId) == FAIL)
      return FAIL;

    // look for the sector we want
    for ( curSector = 0; curSector < numSectors; curSector++ ) {
      newReadCookie = curSector * STM25P_SECTOR_SIZE;
      if (call SectorStorage.read[logId](newReadCookie, &sectorHeader, 
					 sizeof(sectorHeader)) == FAIL)
	return FAIL;
      if (newReadCookie == (cookie & ~(STM25P_SECTOR_SIZE-1)))
	break;
    }
    // couldn't find the sector we want
    if ( curSector >= numSectors )
      return FAIL;

    log[logId].curReadCookie = newReadCookie;

    // scan through
    while ( log[logId].curReadCookie < cookie ) {

      if (advanceCookie(&(log[logId].curReadCookie)) == FAIL)
	return FAIL;

      // if block header is valid
      if ( ~blockHeader.flags & LOG_BLOCK_VALID )
	log[logId].curReadBlockLen = blockHeader.length;
      // if block header is for block that is currently being written
      else if ( log[logId].curReadCookie >= log[logId].curWriteCookie - log[logId].curWriteBlockPos )
	log[logId].curReadBlockLen = log[logId].curWriteBlockPos;

      // advance pointers
      if ( log[logId].curReadCookie + log[logId].curReadBlockLen > cookie ) {
	log[logId].curReadBlockLen = blockHeader.length - log[logId].curReadCookie;
	log[logId].curReadCookie = cookie;
      }
      else {
	log[logId].curReadCookie += blockHeader.length;
      }

    }
    
    if (post signalDoneTask() == SUCCESS) {
      state = S_SEEK;
      return SUCCESS;
    }

    return FAIL;
    
  }

  command result_t LogWrite.erase[logstorage_t logId]() {

    stm25p_addr_t len;

    if (admitRequest(logId) == FAIL)
      return FAIL;

    state = S_ERASE;

    len = call StorageManager.getVolumeSize[logId]();
    if (call SectorStorage.erase[logId](log[logId].curWriteCookie, len) == FAIL) {
      state = S_IDLE;
      return FAIL;
    }

    return SUCCESS;

  }

  result_t appendData() {
    
    stm25p_addr_t addr;
    void* buf;
    log_len_t tmp;

    // commit log block header if at: (1) max block len or (2) end of sector
    if ( log[client].curWriteBlockPos >= LOG_BLOCK_MAX_LENGTH
	 || ( log[client].curWriteBlockPos && !(log[client].curWriteCookie % STM25P_SECTOR_SIZE) ) ) {
      blockHeader.length = log[client].curWriteBlockPos;
      blockHeader.flags = ~( LOG_BLOCK_VALID | LOG_BLOCK_ALLOCATED );
      state = S_COMMIT_BLOCK_HEADER;
      addr = log[client].curWriteCookie - log[client].curWriteBlockPos;
      buf = &blockHeader;
      lastLen = sizeof(blockHeader);
    }

    // write cookie if at start of sector
    else if ( !(log[client].curWriteCookie % STM25P_SECTOR_SIZE) ) {
      sectorHeader.cookie = log[client].curWriteCookie;
      state = S_WRITE_SECTOR_HEADER;
      addr = log[client].curWriteCookie;
      buf = &sectorHeader;
      lastLen = sizeof(sectorHeader);
    }

    // begin log block header
    else if ( !log[client].curWriteBlockPos ) {
      blockHeader.length = LOG_BLOCK_LENGTH_MASK;
      blockHeader.flags = ~( LOG_BLOCK_ALLOCATED );
      state = S_INIT_BLOCK_HEADER;
      addr = log[client].curWriteCookie;
      buf = &blockHeader;
      lastLen = sizeof(blockHeader);
    }

    // write data
    else {

      lastLen = rwLen;
      
      // check for sector boundary
      tmp = STM25P_SECTOR_SIZE - (log[client].curWriteCookie % STM25P_SECTOR_SIZE);
      if ( tmp < lastLen )
	lastLen = tmp;
      
      // check for log block boundary
      tmp = LOG_BLOCK_MAX_LENGTH - log[client].curWriteBlockPos;
      if ( tmp < lastLen )
	lastLen = tmp;
      
      state = S_APPEND;
      addr = log[client].curWriteCookie;
      buf = rwData + curLen;

    }

    return call SectorStorage.write[client](addr, buf, lastLen);

  }

  command result_t LogWrite.append[logstorage_t logId](void* data, log_len_t numBytes) {

    if (admitRequest(logId) == FAIL)
      return FAIL;

    rwData = data;
    rwLen = numBytes;
    curLen = 0;

    if (appendData() == FAIL) {
      state = S_IDLE;
      return FAIL;
    }

    return SUCCESS;

  }

  command result_t LogWrite.sync[logstorage_t logId]() {

    if (admitRequest(logId) == FAIL)
      return FAIL;

    curLen = rwLen = 0;
    blockHeader.length = log[logId].curWriteBlockPos;
    blockHeader.flags = ~(LOG_BLOCK_VALID + LOG_BLOCK_ALLOCATED);
    lastLen = sizeof(blockHeader);

    state = S_SYNC;

    if (call SectorStorage.write[logId](log[logId].curWriteCookie-log[logId].curWriteBlockPos, 
					&blockHeader, lastLen) == FAIL) {
      state = S_IDLE;
      return FAIL;
    }

    return SUCCESS;

  }

  command log_cookie_t LogWrite.currentOffset[logstorage_t logId]() {
    return log[logId].curWriteCookie;
  }

  event void SectorStorage.eraseDone[logstorage_t logId](storage_result_t result) {

    log[logId].curWriteCookie = 0;
    log[logId].curWriteBlockPos = 0;

    signalDone(result);

  }

  event void SectorStorage.writeDone[logstorage_t logId](storage_result_t result) { 
    
    if (state != S_COMMIT_BLOCK_HEADER && state != S_SYNC)
      log[logId].curWriteCookie += lastLen;
    
    if (result != STORAGE_OK) {
      signalDone(result); 
      return;
    }

    switch(state) {
    case S_WRITE_SECTOR_HEADER: 
      break;
    case S_INIT_BLOCK_HEADER: 
      log[logId].curWriteBlockPos += lastLen;
      break;
    case S_COMMIT_BLOCK_HEADER:
    case S_SYNC:
      if (log[logId].curReadCookie >= log[logId].curWriteCookie - log[logId].curWriteBlockPos)
	log[logId].curReadBlockLen = log[logId].curWriteCookie - log[logId].curReadCookie;
      log[logId].curWriteBlockPos = 0;
      break;
    case S_APPEND: 
      log[logId].curWriteBlockPos += lastLen;
      curLen += lastLen;
      break;
    }

    if (curLen >= rwLen) {
      signalDone(result);
    }
    else if (appendData() == FAIL) {
      state = S_APPEND;
      signalDone(STORAGE_FAIL);
    }
    
  }

  default command result_t ActualMount.mount[logstorage_t logId](volume_id_t id) { return FAIL; }
  default command result_t SectorStorage.read[logstorage_t logId](stm25p_addr_t addr, void* data, stm25p_addr_t len) { return FAIL; }
  default command result_t SectorStorage.write[logstorage_t logId](stm25p_addr_t addr, void* data, stm25p_addr_t len) { return FAIL; }
  default command result_t SectorStorage.erase[logstorage_t logId](stm25p_addr_t addr, stm25p_addr_t len) { return FAIL; }
  default command result_t SectorStorage.computeCrc[logstorage_t logId](uint16_t* crcResult, uint16_t crc, stm25p_addr_t addr, stm25p_addr_t len) { return FAIL; }
  default command uint8_t StorageManager.getNumSectors[logstorage_t logId]() { return 0; }
  default command stm25p_addr_t StorageManager.getVolumeSize[logstorage_t logId]() { return STM25P_INVALID_ADDR; }

  default event void LogRead.readDone[logstorage_t logId](storage_result_t result, void* data, log_len_t numBytes) {}
  default event void LogRead.seekDone[logstorage_t logId](storage_result_t result, log_len_t cookie) {}
  default event void LogWrite.eraseDone[logstorage_t logId](storage_result_t result) {}
  default event void LogWrite.appendDone[logstorage_t logId](storage_result_t result, void* data, log_len_t numBytes) {}
  default event void LogWrite.syncDone[logstorage_t logId](storage_result_t result) {}

  default event void Mount.mountDone[logstorage_t logId](storage_result_t result, volume_id_t id) {}

}
