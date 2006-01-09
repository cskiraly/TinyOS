// $Id: FormatStorageM.nc,v 1.1.2.1 2006-01-09 23:25:10 idgay Exp $

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
 * @author Jonathan Hui <jwhui@cs.berkeley.edu>
 * @author David Gay
 */

#include "Storage.h"
#include "StorageManager.h"
#include "crc.h"

module FormatStorageM {
  provides {
    interface FormatStorage;
    interface Init;
  }
  uses {
    interface Resource;
    interface HalAt45db;
  }
}
implementation {
  struct volume_definition_header_t header;
  struct volume_definition_t volumes[MAX_VOLUMES];

  uint8_t state;

  enum {
    S_INIT,
    S_COMMIT, S_COMMIT_HEADER, S_COMMIT_VOLUMES, S_COMMIT_DONE
  };
  
  void signalDone(storage_result_t result) {
    state = S_COMMIT_DONE;
    signal FormatStorage.commitDone(result);
  }

  command error_t Init.init() {
    state = S_COMMIT_DONE;
    return SUCCESS;
  }

  command error_t FormatStorage.init() {
    header.nvolumes = 0;
    state = S_INIT;

    return SUCCESS;
  }

  bool checkNewVolume(volume_id_t id, storage_addr_t addr, storage_addr_t size) {
    volume_id_t i;

    if (state != S_INIT)
      return FALSE;

    if (addr & ((1 << AT45_PAGE_SIZE_LOG2) - 1))
      return FALSE;

    // size must be a multiple of sector size
    if (size & ((1 << AT45_PAGE_SIZE_LOG2) - 1))
      return FALSE;

    // check if id is already taken
    for (i = 0; i < header.nvolumes; i++)
      if (volumes[i].id == id)
	return FALSE;

    return TRUE;
  }

  bool pageWithin(at45page_t page, at45page_t s, at45page_t len) {
    // page - s < len rather page < s + len to avoid overflow
    return page >= s && page - s < len;
  }

  error_t newVolume(uint8_t i, volume_id_t id, at45page_t start, at45page_t length) {
    if (start >= AT45_MAX_PAGES || length > AT45_MAX_PAGES - start)
      return FAIL;

    volumes[i].start = start;
    volumes[i].length = length;
    volumes[i].id = id;
    header.nvolumes++;

    return SUCCESS;
  }

  command error_t FormatStorage.allocate(volume_id_t id, storage_addr_t size) {
    at45page_t addr;
    uint8_t i;

    if (!checkNewVolume(id, 0, size))
      return FAIL;

    size >>= AT45_PAGE_SIZE_LOG2;

    /* First fit. */
    addr = 0;
    for (i = 0; i < header.nvolumes; i++)
      if (addr < volumes[i].start && size < volumes[i].start - addr)
	{
	  memmove(&volumes[i + 1], &volumes[i],
		  (header.nvolumes - i) * sizeof(volumes[i]));
	  break;
	}
      else
	addr = volumes[i].start + volumes[i].length;

    return newVolume(i, id, addr, size);
  }

  command error_t FormatStorage.allocateFixed(volume_id_t id, storage_addr_t addr, storage_addr_t size) {
    uint8_t i;

    if (!checkNewVolume(id, addr, size))
      return FAIL;

    addr >>= AT45_PAGE_SIZE_LOG2;
    size >>= AT45_PAGE_SIZE_LOG2;

    // Check if overlaps any existing allocation
    for (i = 0; i < header.nvolumes; i++)
      if (pageWithin(addr, volumes[i].start, volumes[i].length) ||
	  pageWithin(addr + size - 1, volumes[i].start, volumes[i].length) ||
	  pageWithin(volumes[i].start, addr, size) ||
	  pageWithin(volumes[i].start + volumes[i].length - 1, addr, size))
	return FAIL;

    // Insert at correct position.  These last two loops could be merged,
    // if there was any reason to care about performance
    for (i = 0; i < header.nvolumes; i++)
      if (addr < volumes[i].start)
	{
	  memmove(&volumes[i + 1], &volumes[i],
		  (header.nvolumes - i) * sizeof(volumes[i]));
	  break;
	}

    return newVolume(i, id, addr, size);
  }
   
  uint16_t computeSectorTableCrc() {
    uint16_t crc;
    unsigned char *vtable = (unsigned char *)volumes;
    size_t nvOffset = offsetof(struct volume_definition_header_t, nvolumes);
    size_t i;

    crc = 0;
    /* There may be padding after nvolumes, hence this loop */
    for (i = nvOffset; i < sizeof header; i++)
      crc = crcByte(crc, ((unsigned char *)&header)[i]);
    for (i = 0; i < header.nvolumes * sizeof *volumes; i++)
      crc = crcByte(crc, vtable[i]);

    return crc;
  }

  void commitComplete(error_t x) {
    state = S_COMMIT_DONE;
    signal FormatStorage.commitDone(x == FAIL ? STORAGE_FAIL : STORAGE_OK);
  }


  event void Resource.granted() {
    header.crc = computeSectorTableCrc();
    call HalAt45db.write(VOLUME_TABLE_PAGE, 0, &header, sizeof header);
    state = S_COMMIT_HEADER;
  }

  event void HalAt45db.writeDone(error_t result) {
    if (!(state == S_COMMIT_HEADER || state == S_COMMIT_VOLUMES)) // not for us
      return;

    if (result != SUCCESS)
      commitComplete(result);
    else
      switch (state)
	{
	case S_COMMIT_HEADER:
	  call HalAt45db.write(VOLUME_TABLE_PAGE, sizeof header, &volumes,
			       sizeof *volumes * header.nvolumes);
	  state = S_COMMIT_VOLUMES;
	  break;
	case S_COMMIT_VOLUMES:
	  call HalAt45db.sync(VOLUME_TABLE_PAGE);
	}
  }

  event void HalAt45db.syncDone(error_t result) {
    if (state == S_COMMIT_VOLUMES)
      commitComplete(result);
  }

  event void HalAt45db.eraseDone(error_t result) {
  }

  event void HalAt45db.flushDone(error_t result) {
  }

  event void HalAt45db.readDone(error_t result) {
  }

  event void HalAt45db.computeCrcDone(error_t result, uint16_t crc) {
  }

  command error_t FormatStorage.commit() {
    if (state != S_INIT)
      return FAIL;

    state = S_COMMIT;

    call Resource.request();

    return SUCCESS;
  }
}
