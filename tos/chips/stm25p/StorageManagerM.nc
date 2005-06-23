// $Id: StorageManagerM.nc,v 1.1.2.4 2005-06-23 18:38:43 jwhui Exp $

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
 */

/*
 * @author: Jonathan Hui <jwhui@cs.berkeley.edu>
 */

module StorageManagerM {
  provides {
    interface SectorStorage[volume_t volume];
    interface Mount[volume_t volume];
    interface StdControl;
    interface StorageRemap[volume_t volume];
    interface StorageManager[volume_t volume];
  }
  uses {
    interface Crc;
    interface HALSTM25P;
    interface Leds;
  }
}

implementation {

  enum {
    NUM_VOLUMES = uniqueCount("StorageManager"),
  };

  enum {
    S_NEVER_USED,
    S_READY,
    S_MOUNT,
    S_READ,
    S_COMPUTE_CRC,
    S_WRITE,
    S_ERASE,
  };

  uint8_t state;

  SectorTable sectorTable;
  uint8_t baseSector[NUM_VOLUMES];
  volume_t clientVolume;
  volume_id_t curVolumeId;
  uint16_t crcScratch;
  
  stm25p_addr_t rwAddr;
  stm25p_addr_t rwLen;
  void* rwData;

  command result_t StdControl.init() {

    uint8_t i;
    
    state = S_NEVER_USED;

    for ( i = 0; i < STM25P_NUM_SECTORS; i++ )
      sectorTable.sector[i].volumeId = STM25P_INVALID_VOLUME_ID;

    for ( i = 0; i < NUM_VOLUMES; i++ )
      baseSector[i] = STM25P_INVALID_SECTOR;

    return SUCCESS; 

  }

  command result_t StdControl.start() { 
    return SUCCESS; 
  }

  command result_t StdControl.stop() { 
    return SUCCESS; 
 }

  void signalDone(storage_result_t result) {

    uint8_t tmpState = state;
    state = S_READY;

    switch(tmpState) {
    case S_MOUNT: signal Mount.mountDone[clientVolume](result, curVolumeId); break;
    case S_WRITE: signal SectorStorage.writeDone[clientVolume](result); break;
    case S_ERASE: signal SectorStorage.eraseDone[clientVolume](result); break;
    }
    
  }

  uint16_t computeSectorTableCrc() {
    return call Crc.crc16(&sectorTable, sizeof(SectorTable)-2);
  }

  void actualMount() {

    volume_id_t i;

    // find base sector
    for ( i = 0; i < STM25P_NUM_SECTORS; i++ ) {
      if (sectorTable.sector[i].volumeId == curVolumeId) {
	baseSector[clientVolume] = i;
	signalDone(STORAGE_OK);
	return;
      }
    }

    signalDone(STORAGE_FAIL);

  }

  task void mount() {
    actualMount();
  }

  stm25p_addr_t physicalAddr(stm25p_addr_t volumeAddr) {
    return STM25P_SECTOR_SIZE*baseSector[clientVolume] + volumeAddr;
  }

  stm25p_addr_t calcNumBytes() {

    uint32_t numBytes;

    if ( state == S_MOUNT )
      return STM25P_SECTOR_SIZE;
    else if ( state == S_WRITE )
      numBytes = STM25P_PAGE_SIZE - (rwAddr % STM25P_PAGE_SIZE);
    else 
      numBytes = STM25P_SECTOR_SIZE - (rwAddr % STM25P_SECTOR_SIZE);

    if ( rwLen < numBytes )
      numBytes = rwLen;
    
    return numBytes;
    
  }

  result_t continueOp() {
    stm25p_addr_t pAddr = physicalAddr(rwAddr);

    switch(state) {
    case S_READ: return call HALSTM25P.read(pAddr, rwData, rwLen);
    case S_COMPUTE_CRC: return call HALSTM25P.computeCrc(&crcScratch, crcScratch, pAddr, rwLen);
    case S_MOUNT: pAddr = rwAddr;
    case S_ERASE: return call HALSTM25P.sectorErase(pAddr);
    case S_WRITE: return call HALSTM25P.pageProgram(pAddr, rwData, calcNumBytes());
    }
    return FAIL;
  }

  result_t formatFlash() {

    uint8_t i;

    for ( i = 0; i < STM25P_NUM_SECTORS; i++ )
      sectorTable.sector[i].volumeId = 0xd0 + i;
    sectorTable.crc = computeSectorTableCrc();
    
    rwAddr = 0;
    rwLen = STM25P_SECTOR_SIZE*STM25P_NUM_SECTORS;

    return continueOp();

  }

  command result_t Mount.mount[volume_t volume](volume_id_t volumeID) {

    stm25p_addr_t addr = 0;
    result_t result;
    
    if (state != S_READY && state != S_NEVER_USED)
      return FAIL;
    
    curVolumeId = volumeID;
    clientVolume = volume;

    // if never used, look for partition table
    if (state == S_NEVER_USED) {

      // if never used, find valid sector table
      for ( addr = STM25P_SECTOR_SIZE - sizeof(SectorTable); 
	    addr < STM25P_SECTOR_SIZE*STM25P_NUM_SECTORS;
	    addr += STM25P_SECTOR_SIZE ) {
	if (call HALSTM25P.read(addr, &sectorTable, sizeof(SectorTable)) == FAIL)
	  return FAIL;
	if (sectorTable.crc == computeSectorTableCrc())
	  break;
      }
      
    }

    state = S_MOUNT;
    
    // continue with mount operation
    if ( addr < STM25P_SECTOR_SIZE*STM25P_NUM_SECTORS ) {
      result = post mount();
      if (!result)
	state = S_READY;
    }
    // if flash has no valid sector tables, format it
    else {
      result = formatFlash();
      if (result == FAIL)
	state = S_NEVER_USED;
    }

    return result;

  }

  command uint32_t StorageRemap.physicalAddr[volume_t volume](uint32_t volumeAddr) {
    if (baseSector[volume] == STM25P_INVALID_SECTOR)
      return STM25P_INVALID_ADDR;
    clientVolume = volume;
    return physicalAddr(volumeAddr);
  }

  command uint8_t StorageManager.getNumSectors[volume_t volume]() {
    uint8_t i = baseSector[volume];
    uint8_t tmpVolumeId = sectorTable.sector[i].volumeId;
    
    if (baseSector[volume] == STM25P_INVALID_SECTOR)
      return STM25P_INVALID_SECTOR;
    
    for ( ; i < STM25P_NUM_SECTORS && sectorTable.sector[i].volumeId == tmpVolumeId; i++ );

    return (i - baseSector[volume]);
  }

  command stm25p_addr_t StorageManager.getVolumeSize[volume_t volume]() {
    if (baseSector[volume] == STM25P_INVALID_SECTOR)
      return STM25P_INVALID_ADDR;
    return STM25P_SECTOR_SIZE * call StorageManager.getNumSectors[volume]();
  }

  result_t newRequest(uint8_t newState, volume_t volume, 
		      stm25p_addr_t addr, void* data, stm25p_addr_t len) {

    result_t result;

    if (state != S_READY)
      return FALSE;

    state = newState;
    clientVolume = volume;

    rwAddr = addr;
    rwData = data;
    rwLen = len;

    result = continueOp();

    if (result == FAIL || state == S_READ || state == S_COMPUTE_CRC)
      state = S_READY;

    return result;

  }

  command result_t SectorStorage.read[volume_t volume](stm25p_addr_t addr, void* data, stm25p_addr_t len) {
    return newRequest(S_READ, volume, addr, data, len);
  }

  command result_t SectorStorage.write[volume_t volume](stm25p_addr_t addr, void* data, stm25p_addr_t len) {
    return newRequest(S_WRITE, volume, addr, data, len);
  }

  command result_t SectorStorage.erase[volume_t volume](stm25p_addr_t addr, stm25p_addr_t len) {
    return newRequest(S_ERASE, volume, addr, NULL, 0);
  }

  command result_t SectorStorage.computeCrc[volume_t volume](uint16_t* crcResult, uint16_t crc, 
							     stm25p_addr_t addr, stm25p_addr_t len) {
    result_t result;
    crcScratch = crc;
    result = newRequest(S_COMPUTE_CRC, volume, addr, NULL, len);
    *crcResult = crcScratch;
    return result;
  }

  void pageProgramDone() {

    stm25p_addr_t lastBytes;
    
    lastBytes = calcNumBytes();
    rwAddr += lastBytes;
    rwData += lastBytes;
    rwLen -= lastBytes;
    if ( rwLen == 0 ) {
      if (state == S_MOUNT)
	actualMount();
      else
	signalDone(STORAGE_OK);
      return;
    }

    if (continueOp() == FAIL)
      signalDone(STORAGE_FAIL);

  }

  event void HALSTM25P.pageProgramDone() {
    pageProgramDone();
  }

  event void HALSTM25P.sectorEraseDone() {

    uint8_t sector = rwAddr / STM25P_SECTOR_SIZE;

    if (state != S_MOUNT)
      sector += baseSector[clientVolume];

    if ( sector == STM25P_NUM_SECTORS - 1 ||
	 sectorTable.sector[sector].volumeId != sectorTable.sector[sector+1].volumeId ) {
      stm25p_addr_t addr = STM25P_SECTOR_SIZE*(sector+1) - sizeof(SectorTable);
      if (call HALSTM25P.pageProgram(addr, &sectorTable, sizeof(SectorTable)) == FAIL)
	signalDone(STORAGE_FAIL);
    }
    else {
      pageProgramDone();
    }

  }

  event void HALSTM25P.bulkEraseDone() {}
  event void HALSTM25P.writeSRDone() {}

  default event void Mount.mountDone[volume_t volume](storage_result_t result, volume_id_t id) {}
  default event void SectorStorage.eraseDone[volume_t volume](result_t result) {}
  default event void SectorStorage.writeDone[volume_t volume](result_t result) {}

}
