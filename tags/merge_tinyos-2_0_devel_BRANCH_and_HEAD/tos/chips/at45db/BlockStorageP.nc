// $Id: BlockStorageP.nc,v 1.1.2.18 2006-11-07 23:14:59 scipio Exp $

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
 *
 * Copyright (c) 2002-2006 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */

/**
 * Private component of the AT45DB implementation of the block storage
 * abstraction.
 *
 * @author: Jonathan Hui <jwhui@cs.berkeley.edu>
 * @author: David Gay <dgay@acm.org>
 */

#include "Storage.h"

module BlockStorageP {
  provides {
    interface BlockWrite[uint8_t blockId];
    interface BlockRead[uint8_t blockId];
  }
  uses {
    interface At45db;
    interface At45dbVolume[uint8_t blockId];
    interface Resource[uint8_t blockId];
    interface At45dbBlockConfig as BConfig[uint8_t blockId];
  }
}
implementation 
{
  /* The AT45DB block storage implementation simply provides direct
     read/write access to the underlying pages of the volume. Random
     writes to the block storage will thus lead to pages being 
     erased/programmed many times (there is a 2 page cache, but
     random writes are unlikely to hit in it).

     The cache is only flushed on sync.

     The first page of a block storage volume stores the maximum address
     written in the block and a CRC of the block's contents (up to that
     maximum address). This CRC is written at sync time and verified at
     validate time.

     This BlockStorage code is reused in the implementation of
     ConfigStorage.  See the ConfigStorageP component and the
     At45dbBlockConfig interface for more discussion. If there are m
     ConfigStorage volumes and n BlockStorage volumes, the ids 0..m-1 are
     for ConfigStorage and m..m+n-1 are for BlockStorage.
  */

  enum {
    R_IDLE,
    R_WRITE,
    R_ERASE,
    R_SYNC,
    R_READ,
    R_CRC,
  };

  enum {
    N = uniqueCount(UQ_BLOCK_STORAGE) + uniqueCount(UQ_CONFIG_STORAGE),
    NO_CLIENT = 0xff
  };

  uint8_t client = NO_CLIENT;
  storage_addr_t bytesRemaining;

  struct {
    /* The latest request made for this client, and it's arguments */
    uint8_t request; /* automatically initialised to R_IDLE */
    uint8_t *buf;
    storage_addr_t addr;
    storage_len_t len;
  } s[N];


  /* ------------------------------------------------------------------ */
  /* Interface with ConfigStorageP (see also writeHook call below)	*/
  /* ------------------------------------------------------------------ */

  at45page_t pageRemap(at45page_t p) {
    return signal BConfig.remap[client](p);
  }

  event at45page_t BConfig.npages[uint8_t id]() {
    return call At45dbVolume.volumeSize[id]() >> 1;
  }

  event at45page_t BConfig.remap[uint8_t id](at45page_t page) {
    if (call BConfig.isConfig[id]() && call BConfig.flipped[id]())
      page += signal BConfig.npages[id]();
    return call At45dbVolume.remap[id](page);
  }

  default command int BConfig.isConfig[uint8_t blockId]() {
    return FALSE;
  }

  default command int BConfig.flipped[uint8_t blockId]() {
    return FALSE;
  }

  /* ------------------------------------------------------------------ */
  /* Queue and initiate user requests					*/
  /* ------------------------------------------------------------------ */

  void eraseStart();
  void syncStart();
  void multipageStart(storage_len_t len, uint16_t crc);

  void startRequest() {
    switch (s[client].request)
      {
      case R_ERASE:
	eraseStart();
	break;
      case R_SYNC:
	syncStart();
	break;
      default:
	multipageStart(s[client].len, (uint16_t)s[client].buf);
      }
  }

  void endRequest(error_t result, uint16_t crc) {
    uint8_t c = client;
    uint8_t tmpState = s[c].request;
    storage_addr_t actualLength = s[c].len - bytesRemaining;
    storage_addr_t addr = s[c].addr - actualLength;
    void *ptr = s[c].buf - actualLength;
    
    client = NO_CLIENT;
    s[c].request = R_IDLE;
    call Resource.release[c]();

    switch(tmpState)
      {
      case R_READ:
	signal BlockRead.readDone[c](addr, ptr, actualLength, result);
	break;
      case R_WRITE:
	signal BlockWrite.writeDone[c](addr, ptr, actualLength, result);
	break;
      case R_ERASE:
	signal BlockWrite.eraseDone[c](result);
	break;
      case R_CRC:
	signal BlockRead.computeCrcDone[c](addr, actualLength, crc, result);
	break;
      case R_SYNC:
	signal BlockWrite.syncDone[c](result);
	break;
      }
  }

  error_t newRequest(uint8_t newState, uint8_t id,
		       storage_addr_t addr, uint8_t* buf, storage_len_t len) {
    storage_len_t vsize;

    if (s[id].request != R_IDLE)
      return EBUSY;

    vsize = call BlockRead.getSize[id]();
    if (addr > vsize || len > vsize - addr)
      return EINVAL;

    s[id].request = newState;
    s[id].addr = addr;
    s[id].buf = buf;
    s[id].len = len;

    call Resource.request[id]();

    return SUCCESS;
  }

  event void Resource.granted[uint8_t blockId]() {
    client = blockId;

    if (s[blockId].request == R_WRITE &&
	call BConfig.writeHook[blockId]())
      {
	/* Config write intercept. We'll get a writeContinue when it's
	   time to resume. */
	client = NO_CLIENT;
	return;
      }
    startRequest();
  }

  default command int BConfig.writeHook[uint8_t blockId]() {
    return FALSE;
  }

  event void BConfig.writeContinue[uint8_t blockId](error_t error) {
    /* Config intercept complete. Resume operation. */
    client = blockId;
    if (error == SUCCESS)
      startRequest();
    else
      endRequest(error, 0);
  }

  /* ------------------------------------------------------------------ */
  /* Multipage operations            					*/
  /* ------------------------------------------------------------------ */

  void calcRequest(storage_addr_t addr, at45page_t *page,
		   at45pageoffset_t *offset, at45pageoffset_t *count) {
    *page = pageRemap(addr >> AT45_PAGE_SIZE_LOG2);
    *offset = addr & ((1 << AT45_PAGE_SIZE_LOG2) - 1);
    if (bytesRemaining < (1 << AT45_PAGE_SIZE_LOG2) - *offset)
      *count = bytesRemaining;
    else
      *count = (1 << AT45_PAGE_SIZE_LOG2) - *offset;

  }

  void multipageContinue(uint16_t crc) {
    at45page_t page;
    at45pageoffset_t offset, count;
    uint8_t *buf = s[client].buf;

    if (bytesRemaining == 0)
      {
	endRequest(SUCCESS, crc);
	return;
      }

    calcRequest(s[client].addr, &page, &offset, &count);
    bytesRemaining -= count;
    s[client].addr += count;
    s[client].buf = buf + count;

    switch (s[client].request)
      {
      case R_WRITE:
	call At45db.write(page, offset, buf, count);
	break;
      case R_READ:
	call At45db.read(page, offset, buf, count);
	break;
      case R_CRC:
	call At45db.computeCrc(page, offset, count, crc);
	break;
      }
  }

  void multipageStart(storage_len_t len, uint16_t crc) {
    bytesRemaining = len;
    multipageContinue(crc);
  }

  void multipageOpDone(error_t result, uint16_t crc) {
    if (result != SUCCESS)
      endRequest(result, 0);
    else
      multipageContinue(crc);
  }

  /* ------------------------------------------------------------------ */
  /* Erase								*/
  /* ------------------------------------------------------------------ */

  command error_t BlockWrite.erase[uint8_t id]() {
    return newRequest(R_ERASE, id, 0, NULL, 0);
  }

  void eraseStart() {
    call At45db.erase(pageRemap(0), AT45_ERASE);
  }

  void eraseEraseDone(error_t error) {
    endRequest(error, 0);
  }

  /* ------------------------------------------------------------------ */
  /* Write								*/
  /* ------------------------------------------------------------------ */

  command error_t BlockWrite.write[uint8_t id](storage_addr_t addr, void* buf, storage_len_t len) {
    return newRequest(R_WRITE, id, addr, buf, len);
  }

  /* ------------------------------------------------------------------ */
  /* Sync								*/
  /* ------------------------------------------------------------------ */

  command error_t BlockWrite.sync[uint8_t id]() {
    return newRequest(R_SYNC, id, 0, NULL, 0);
  }

  void syncStart() {
    call At45db.syncAll();
  }

  void syncSyncDone(error_t error) {
    endRequest(error, 0);
  }

  /* ------------------------------------------------------------------ */
  /* Read								*/
  /* ------------------------------------------------------------------ */

  command error_t BlockRead.read[uint8_t id](storage_addr_t addr, void* buf, storage_len_t len) {
    return newRequest(R_READ, id, addr, buf, len);
  }

  /* ------------------------------------------------------------------ */
  /* Compute CRC							*/
  /* ------------------------------------------------------------------ */

  command error_t BlockRead.computeCrc[uint8_t id](storage_addr_t addr, storage_len_t len, uint16_t basecrc) {
    return newRequest(R_CRC, id, addr, (void *)basecrc, len);
  }

  /* ------------------------------------------------------------------ */
  /* Get Size								*/
  /* ------------------------------------------------------------------ */

  command storage_len_t BlockRead.getSize[uint8_t blockId]() {
    storage_len_t vsize;

    if (call BConfig.isConfig[blockId]())
      vsize = signal BConfig.npages[blockId]();
    else
      vsize = call At45dbVolume.volumeSize[blockId]();

    return vsize << AT45_PAGE_SIZE_LOG2;
  }

  /* ------------------------------------------------------------------ */
  /* Dispatch HAL operations to current user op				*/
  /* ------------------------------------------------------------------ */

  event void At45db.writeDone(error_t result) {
    if (client != NO_CLIENT)
      multipageOpDone(result, 0);
  }

  event void At45db.readDone(error_t result) {
    if (client != NO_CLIENT)
      multipageOpDone(result, 0);
  }

  event void At45db.computeCrcDone(error_t result, uint16_t newCrc) {
    if (client != NO_CLIENT)
      multipageOpDone(result, newCrc);
  }

  event void At45db.eraseDone(error_t result) {
    if (client != NO_CLIENT)
      eraseEraseDone(result);
  }

  event void At45db.syncDone(error_t result) {
    if (client != NO_CLIENT)
      syncSyncDone(result);
  }

  event void At45db.flushDone(error_t result) { }
  event void At45db.copyPageDone(error_t error) { }
  default event void BlockWrite.writeDone[uint8_t id](storage_addr_t addr, void* buf, storage_len_t len, error_t result) { }
  default event void BlockWrite.eraseDone[uint8_t id](error_t result) { }
  default event void BlockWrite.syncDone[uint8_t id](error_t result) { }
  default event void BlockRead.readDone[uint8_t id](storage_addr_t addr, void* buf, storage_len_t len, error_t result) { }
  default event void BlockRead.computeCrcDone[uint8_t id](storage_addr_t addr, storage_len_t len, uint16_t x, error_t result) { }
  
  default command at45page_t At45dbVolume.remap[uint8_t id](at45page_t volumePage) { return 0; }
  default command at45page_t At45dbVolume.volumeSize[uint8_t id]() { return 0; }
  default async command error_t Resource.request[uint8_t id]() { return FAIL; }
  default async command error_t Resource.release[uint8_t id]() { return FAIL; }
}
