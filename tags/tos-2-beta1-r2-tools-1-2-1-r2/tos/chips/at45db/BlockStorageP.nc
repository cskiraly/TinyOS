// $Id: BlockStorageP.nc,v 1.1.2.6 2006-02-03 23:23:06 idgay Exp $

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
    interface BlockWrite[blockstorage_t blockId];
    interface BlockRead[blockstorage_t blockId];
  }
  uses {
    interface At45db;
    interface At45dbVolume[blockstorage_t blockId];
    interface Resource[blockstorage_t blockId];
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
    S_VERIFY, S_VERIFY2,
    S_CRC,
  };

  enum {
    N = uniqueCount(UQ_BLOCK_STORAGE),
    NO_CLIENT = 0xff
  };

  uint8_t client = NO_CLIENT;
  storage_addr_t bytesRemaining;
  uint16_t crc;

  /* The requests */
  uint8_t state[N]; /* automatically initialised to S_IDLE */
  uint8_t *bufPtr[N];
  storage_addr_t curAddr[N];
  storage_len_t requestedLength[N];

  storage_addr_t maxAddr[N];
  uint8_t sig[8];

  void verifySignature();
  void commitSignature();
  void commitSync();
  void continueRequest();

  void setupRequest(uint8_t newState, blockstorage_t id,
		    storage_addr_t addr, uint8_t* buf, storage_len_t len) {
    state[id] = newState;
    curAddr[id] = addr;
    bufPtr[id] = buf;
    requestedLength[id] = len;
  }

  error_t newRequest(uint8_t newState, blockstorage_t id,
		       storage_addr_t addr, uint8_t* buf, storage_len_t len) {
    if (state[id] != S_IDLE)
      return FAIL;

    setupRequest(newState, id, addr, buf, len);

    call Resource.request[id]();

    return SUCCESS;
  }

  event void Resource.granted[blockstorage_t blockId]() {
    client = blockId;
    bytesRemaining = requestedLength[client];
    crc = 0;
    continueRequest();
  }

  void actualSignal(error_t result) {
    blockstorage_t c = client;
    uint8_t tmpState = state[c];
    storage_addr_t actualLength = requestedLength[c] - bytesRemaining;
    storage_addr_t addr = curAddr[c] - actualLength;
    void *ptr = bufPtr[c] - actualLength;
    
    client = NO_CLIENT;
    state[c] = S_IDLE;
    call Resource.release[c]();

    switch(tmpState)
      {
      case S_READ:
	signal BlockRead.readDone[c](addr, ptr, actualLength, result);
	break;
      case S_WRITE:
	signal BlockWrite.writeDone[c](addr, ptr, actualLength, result);
	break;
      case S_ERASE:
	signal BlockWrite.eraseDone[c](result);
	break;
      case S_CRC:
	signal BlockRead.computeCrcDone[c](addr, actualLength, crc, result);
	break;
      case S_COMMIT: case S_COMMIT2: case S_COMMIT3:
	signal BlockWrite.commitDone[c](result);
	break;
      case S_VERIFY: case S_VERIFY2: 
	signal BlockRead.verifyDone[c](result);
	break;
      }
  }

  task void signalSuccess() { actualSignal(SUCCESS); }
  
  task void signalFail() { actualSignal(FAIL); }

  void signalDone(error_t result) {
    if (result == SUCCESS)
      switch (state[client])
	{
	case S_COMMIT: commitSignature(); break;
	case S_COMMIT2: commitSync(); break;
	case S_VERIFY: verifySignature(); break;
	case S_VERIFY2: 
	  if (crc == (sig[0] | (uint16_t)sig[1] << 8))
	    actualSignal(SUCCESS);
	  else
	    actualSignal(FAIL);
	  break;
	default: post signalSuccess(); break;
	}
    else
      post signalFail();
  }

  void calcRequest(storage_addr_t addr, at45page_t *page,
		   at45pageoffset_t *offset, at45pageoffset_t *count) {
    *page = call At45dbVolume.remap[client](addr >> AT45_PAGE_SIZE_LOG2);
    *offset = addr & ((1 << AT45_PAGE_SIZE_LOG2) - 1);
    if (bytesRemaining < (1 << AT45_PAGE_SIZE_LOG2) - *offset)
      *count = bytesRemaining;
    else
      *count = (1 << AT45_PAGE_SIZE_LOG2) - *offset;
  }

  void continueRequest() {
    at45page_t page;
    at45pageoffset_t offset, count;
    uint8_t *buf = bufPtr[client];

    calcRequest(curAddr[client], &page, &offset, &count);
    bytesRemaining -= count;
    curAddr[client] += count;
    bufPtr[client] += count;

    switch (state[client])
      {
      case S_WRITE:
	call At45db.write(page, offset, buf, count);
	break;
      case S_READ:
	call At45db.read(page, offset, buf, count);
	break;
      case S_CRC: case S_COMMIT: case S_VERIFY2:
	call At45db.computeCrc(page, offset, count, crc);
	break;
      case S_ERASE:
	call At45db.erase(page, AT45_ERASE);
	break;
      case S_VERIFY:
	call At45db.read(page, 1 << AT45_PAGE_SIZE_LOG2, sig, sizeof sig);
	break;
      }
  }

  command error_t BlockWrite.write[blockstorage_t id](storage_addr_t addr, void* buf, storage_len_t len) {
    error_t ok = newRequest(S_WRITE, id, addr, buf, len);

    if (ok == SUCCESS && addr + len > maxAddr[id])
      maxAddr[id] = addr + len;

    return ok;
  }

  command error_t BlockWrite.erase[blockstorage_t id]() {
    return newRequest(S_ERASE, id, 0, NULL, 0);
  }

  command error_t BlockWrite.commit[blockstorage_t id]() {
    return newRequest(S_COMMIT, id, 0, NULL, maxAddr[id]);
  }

  /* Called once crc computed. Write crc + signature in block 0. */
  void commitSignature() {
    sig[0] = crc;
    sig[1] = crc >> 8;
    sig[2] = maxAddr[client];
    sig[3] = maxAddr[client] >> 8;
    sig[4] = maxAddr[client] >> 16;
    sig[5] = maxAddr[client] >> 24;
    sig[6] = 0xb1; /* block sig: b10c */
    sig[7] = 0x0c;
    state[client] = S_COMMIT2;
    /* Note: bytesRemaining is 0, so multipageDone will go straight to
       signalDone */
    call At45db.write(call At45dbVolume.remap[client](0),
			 1 << AT45_PAGE_SIZE_LOG2, sig, sizeof sig);
  }

  /* Called once signature written. Ensure writes complete. */
  void commitSync() {
    state[client] = S_COMMIT3;
    call At45db.syncAll();
  }

#if 0
  command uint32_t BlockRead.getSize[blockstorage_t blockId]() {
    return call At45dbVolume.volumeSize[blockId]();
  }
#endif

  command error_t BlockRead.read[blockstorage_t id](storage_addr_t addr, void* buf, storage_len_t len) {
    return newRequest(S_READ, id, addr, buf, len);
  }

  command error_t BlockRead.verify[blockstorage_t id]() {
    return newRequest(S_VERIFY, id, 0, NULL, 0);
  }

  /* See commitSignature */
  void verifySignature() {
    if (sig[6] == 0xb1 && sig[7] == 0x0c)
      {
	maxAddr[client] = sig[2] | (uint32_t)sig[3] << 8 |
	  (uint32_t)sig[4] << 16 | (uint32_t)sig[5] << 24;
	setupRequest(S_VERIFY2, client, 0, NULL, maxAddr[client]);
	signal Resource.granted[client]();
      }
    else
      actualSignal(FAIL);
  }

  command error_t BlockRead.computeCrc[blockstorage_t id](storage_addr_t addr, storage_len_t len) {
    return newRequest(S_CRC, id, addr, NULL, len);
  }

  void multipageDone(error_t result) {
    if (client != NO_CLIENT)
      if (bytesRemaining == 0 || result == FAIL)
	signalDone(result);
      else
	continueRequest();
  }

  event void At45db.writeDone(error_t result) {
    multipageDone(result);
  }

  event void At45db.readDone(error_t result) {
    multipageDone(result);
  }

  event void At45db.computeCrcDone(error_t result, uint16_t newCrc) {
    crc = newCrc;
    multipageDone(result);
  }

  event void At45db.eraseDone(error_t result) {
    if (client != NO_CLIENT)
      signalDone(result);
  }

  event void At45db.syncDone(error_t result) {
    if (client != NO_CLIENT)
      signalDone(result);
  }

  event void At45db.flushDone(error_t result) {
  }

  default event void BlockWrite.writeDone[uint8_t id](storage_addr_t addr, void* buf, storage_len_t len, error_t result) { }
  default event void BlockWrite.eraseDone[uint8_t id](error_t result) { }
  default event void BlockWrite.commitDone[uint8_t id](error_t result) { }
  default event void BlockRead.readDone[uint8_t id](storage_addr_t addr, void* buf, storage_len_t len, error_t result) { }
  default event void BlockRead.verifyDone[uint8_t id](error_t result) { }
  default event void BlockRead.computeCrcDone[uint8_t id](storage_addr_t addr, storage_len_t len, uint16_t x, error_t result) { }
  
  default command at45page_t At45dbVolume.remap[blockstorage_t id](at45page_t volumePage) { return 0; }
  default command storage_addr_t At45dbVolume.volumeSize[blockstorage_t id]() { return 0; }
  default async command error_t Resource.request[blockstorage_t id]() { return FAIL; }
  default async command void Resource.release[blockstorage_t id]() { }
}
