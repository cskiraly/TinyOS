// $Id: FormatStorageM.nc,v 1.1.2.1 2005-06-07 20:05:35 jwhui Exp $

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

module FormatStorageM {
  provides {
    interface FormatStorage;
    interface StdControl;
  }
  uses {
    interface Crc;
    interface HALSTM25P;
  }
}

implementation {

  SectorTable sectorTable;
  stm25p_addr_t curAddr;

  uint8_t state;

  enum {
    S_INIT,
    S_COMMIT,
    S_COMMIT_DONE,
  };
  
  void signalDone(storage_result_t result) {
    state = S_COMMIT_DONE;
    signal FormatStorage.commitDone(result);
  }

  command result_t StdControl.init() {
    state = S_COMMIT_DONE;
    return SUCCESS;
  }

  command result_t StdControl.start() {
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }

  command result_t FormatStorage.init() {

    volume_id_t i;

    if (state == S_COMMIT)
      return FAIL;

    state = S_INIT;

    for ( i = 0; i < STM25P_NUM_SECTORS; i++ )
      sectorTable.sector[i].volumeId = STM25P_INVALID_VOLUME_ID;

    return SUCCESS;

  }

  result_t allocate(volume_id_t id, storage_addr_t addr, storage_addr_t size) {

    volume_id_t freeSectors;
    uint8_t base;
    volume_id_t i;

    if (state != S_INIT)
      return FAIL;

    if (addr % STM25P_SECTOR_SIZE)
      return FAIL;

    // size must be a multiple of sector size
    if (size % STM25P_SECTOR_SIZE)
      return FAIL;

    addr /= STM25P_SECTOR_SIZE;
    size /= STM25P_SECTOR_SIZE;

    // check if id is already taken
    for ( i = 0; i < STM25P_NUM_SECTORS; i++ ) {
      if (sectorTable.sector[i].volumeId == id)
	return FAIL;
    }
    
    // count number of free sectors
    for ( i = addr, freeSectors = 0, base = addr; i < STM25P_NUM_SECTORS && freeSectors < size; i++ ) {
      if (sectorTable.sector[i].volumeId == STM25P_INVALID_VOLUME_ID) {
	freeSectors++;
      }
      else {
	// if trying to allocate fixed, return fail
	if (addr != 0)
	  return FAIL;
	freeSectors = 0;
	base = i + 1;
      }
    }

    // check if there are enough free sectors
    if (freeSectors < size)
      return FAIL;

    // allocate space
    for ( i = base; i < STM25P_NUM_SECTORS && size > 0; i++, size-- )
      sectorTable.sector[i].volumeId = id;

    return SUCCESS;

  }

  command result_t FormatStorage.allocate(volume_id_t id, storage_addr_t size) {
    return allocate(id, 0, size);
  }

  command result_t FormatStorage.allocateFixed(volume_id_t id, storage_addr_t addr, storage_addr_t size) {
    return allocate(id, addr, size);
  }
   
  uint16_t computeSectorTableCrc() {
    return call Crc.crc16(&sectorTable, sizeof(SectorTable)-2);
  }

  command result_t FormatStorage.commit() {

    if (state != S_INIT)
      return FAIL;

    state = S_COMMIT;

    sectorTable.crc = computeSectorTableCrc();

    curAddr = STM25P_SECTOR_SIZE - sizeof(SectorTable);

    if (call HALSTM25P.sectorErase(curAddr) == FAIL) {
      state = S_INIT;
      return FAIL;
    }

    return SUCCESS;

  }

  void pageProgramDone() {

    curAddr += STM25P_SECTOR_SIZE;

    if ( curAddr < STM25P_SECTOR_SIZE * STM25P_NUM_SECTORS ) {
      if (call HALSTM25P.sectorErase(curAddr) == FAIL) {
	state = S_INIT;
	signalDone(STORAGE_FAIL);
      }
      return;
    }
    
    signalDone(STORAGE_OK);

  }

  event void HALSTM25P.sectorEraseDone() { 

    uint8_t sector = curAddr / STM25P_SECTOR_SIZE;

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

  event void HALSTM25P.pageProgramDone() {
    pageProgramDone();
  }

  event void HALSTM25P.bulkEraseDone() {}
  event void HALSTM25P.writeSRDone() {}

}
