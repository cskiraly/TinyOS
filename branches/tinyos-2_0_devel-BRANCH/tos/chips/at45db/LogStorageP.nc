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
 * Private component of the AT45DB implementation of the log storage
 * abstraction.
 *
 * @author: David Gay <dgay@acm.org>
 * @author: Jonathan Hui <jwhui@cs.berkeley.edu>
 */

#include <Storage.h>
#include <crc.h>

module LogStorageP {
  provides {
    interface LogWrite as LinearWrite[logstorage_t logId];
    interface LogRead as LinearRead[logstorage_t logId];
    //interface LogWrite as CircularWrite[logstorage_t logId];
    //interface LogRead as CircularRead[logstorage_t logId];
  }
  uses {
    interface At45db;
    interface At45dbVolume[logstorage_t logId];
    interface Resource[logstorage_t logId];
  }
}
implementation
{
  enum {
    F_SYNC = 1,
    F_CIRCLED = 2,
    F_LASTVALID = 4,
    F_FIRSTVALID = 8
  };

  nx_struct pageinfo {
    nx_uint16_t magic;
    nx_uint32_t offset;
    nx_uint8_t firstRecordOffset, lastRecordOffset;
    nx_uint8_t flags;
    nx_uint16_t crc;
  };

  enum {
    N = uniqueCount(UQ_LOG_STORAGE),
    NO_CLIENT = 0xff,
    PAGE_SIZE = AT45_PAGE_SIZE - sizeof(nx_struct pageinfo),
    PERSISTENT_MAGIC = 0x4256,
  };

  enum {
    S_IDLE,
    S_ERASE,
    S_APPEND,
    S_SYNC,
    S_READ,
  };

  enum {
    META_IDLE,
    META_LOCATE,
    META_LOCATELAST,
    META_READ,
    META_WRITE
  };

  uint8_t client = NO_CLIENT;
  uint8_t metaState;
  at45page_t firstPage, lastPage;
  storage_len_t len;
  nx_struct pageinfo metadata;


  struct {
    /* The latest request made for this client, and it's arguments */
    uint8_t request; 
    uint8_t *buf;
    storage_len_t len;

    /* Log r/w positions */
    bool positionKnown : 1;
    at45page_t wpage;		/* Current write page */
    at45pageoffset_t woffset;	/* Offset on current write page */
    at45page_t rpage;		/* Current read page */
    at45pageoffset_t roffset;	/* Offset on current read page */
    at45pageoffset_t rend;	/* Last valid offset on current read page */
  } s[N];

  at45page_t firstVolumePage() {
    return call At45dbVolume.remap[client](0);
  }

  at45page_t lastVolumePage() {
    return call At45dbVolume.remap[client](call At45dbVolume.volumeSize[client]() >> AT45_PAGE_SIZE_LOG2);
  }

  void setWritePage(at45page_t page) {
    s[client].wpage = page;
    s[client].woffset = 0;
  }

  void setReadPage(at45page_t page) {
    /* Set position to end of previous page, to force page advance
       on next read */
    s[client].rpage = page - 1;
    s[client].rend = s[client].roffset = 0;
  }

  void crcPage(at45page_t page) {
    call At45db.computeCrc(page, 0,
			   PAGE_SIZE + offsetof(nx_struct pageinfo, crc), 0);
  }

  void readMetadata(at45page_t page) {
    call At45db.read(page, PAGE_SIZE, &metadata, sizeof metadata);
  }

  void writeMetadata(at45page_t page) {
    call At45db.write(page, PAGE_SIZE, &metadata, sizeof metadata);
  }

  /* ------------------------------------------------------------------ */
  /* Queue and initiate user requests					*/
  /* ------------------------------------------------------------------ */

  void eraseStart();
  void appendStart();
  void syncStart();
  void readStart();
  void locateStart();
  void rmetadataStart();
  void wmetadataStart();

  void startRequest() {
    if (!s[client].positionKnown && s[client].request != S_ERASE)
      {
	locateStart();
	return;
      }

    switch (s[client].request)
      {
      case S_ERASE: eraseStart(); break;
      case S_APPEND: appendStart(); break;
      case S_SYNC: syncStart(); break;
      case S_READ: readStart(); break;
      }
  }

  void endRequest(error_t ok) {
    logstorage_t c = client;
    uint8_t request = s[c].request;
    storage_len_t actualLen = s[c].len - len;
    void *ptr = s[c].buf - actualLen;
    
    client = NO_CLIENT;
    s[c].request = S_IDLE;
    call Resource.release[c]();

    switch (request)
      {
      case S_ERASE: signal LinearWrite.eraseDone[c](ok); break;
      case S_APPEND: signal LinearWrite.appendDone[c](ptr, actualLen, ok); break;
      case S_SYNC: signal LinearWrite.syncDone[c](ok); break;
      case S_READ: signal LinearRead.readDone[c](ptr, actualLen, ok); break;
      }
  }

  void setupRequest(uint8_t newRequest, logstorage_t id,
		    uint8_t *buf, storage_len_t length) {
    s[id].request = newRequest;
    s[id].buf = buf;
    s[id].len = length;
  }

  error_t newRequest(uint8_t newRequest, logstorage_t id,
		     uint8_t *buf, storage_len_t length) {
    if (s[id].request != S_IDLE)
      return FAIL;
    setupRequest(newRequest, id, buf, length);
    call Resource.request[id]();

    return SUCCESS;
  }

  event void Resource.granted[logstorage_t id]() {
    client = id;
    len = s[client].len;
    metaState = META_IDLE;
    startRequest();
  }

  command error_t LinearWrite.append[logstorage_t id](void* buf, storage_len_t length) {
    return newRequest(S_APPEND, id, buf, length);
  }

  command uint32_t LinearWrite.currentOffset[logstorage_t id]() {
   return 0;
  }

  command error_t LinearWrite.erase[logstorage_t id]() {
    return newRequest(S_ERASE, id, NULL, 0);
  }

  command error_t LinearWrite.sync[logstorage_t id]() {
    return newRequest(S_SYNC, id, NULL, 0);
  }

  command error_t LinearRead.read[logstorage_t id](void* buf, storage_len_t length) {
    return newRequest(S_READ, id, buf, length);
  }

  command uint32_t LinearRead.currentOffset[logstorage_t id]() {
    return 0;
  }

  command error_t LinearRead.seek[logstorage_t id](uint32_t offset) {
    return FAIL;
  }

  /* ------------------------------------------------------------------ */
  /* Erase								*/
  /* ------------------------------------------------------------------ */

  void eraseContinue() {
    /* We erase backwards. That leaves the first two pages in the cache */
    if (lastPage == firstPage)
      {
	s[client].positionKnown = TRUE;
	setReadPage(firstPage);
	setWritePage(firstPage);
	endRequest(SUCCESS);
      }
    else
      call At45db.erase(--lastPage, AT45_ERASE);
  }

  void eraseStart() {
    firstPage = firstVolumePage();
    lastPage = lastVolumePage();
    eraseContinue();
  }

  /* ------------------------------------------------------------------ */
  /* Locate log boundaries						*/
  /* ------------------------------------------------------------------ */

  void locateLastRecord() {
    if (firstPage == firstVolumePage())
      {
	/* Nothing valid found. We're done (log is empty). */
	s[client].positionKnown = TRUE;
	startRequest();
      }
    else
      readMetadata(--firstPage);
  }

  void locateLastReadDone() {
    if (metadata.magic == PERSISTENT_MAGIC && metadata.flags & F_LASTVALID)
      crcPage(firstPage);
    else
      locateLastRecord();
  }

  void locateLastCrcDone(uint16_t crc) {
    if (crc == metadata.crc)
      {
	/* We've found the last valid page with a record-end */
	s[client].positionKnown = TRUE;
	if (metadata.flags & F_SYNC) /* must start on next page */
	  setWritePage(firstPage + 1);
	else
	  {
	    s[client].wpage = firstPage;
	    s[client].woffset = metadata.lastRecordOffset;
	  }
	startRequest();
      }
    else
      locateLastRecord();
  }

  void located() {
    metaState = META_LOCATELAST;
    /* firstPage is one after last valid page, but the last page with
       a record end may be some pages earlier. Search for it. */
    locateLastRecord();
  }

  at45page_t locateCurrentPage() {
    return firstPage + ((lastPage - firstPage + 1) >> 1);
  }

  void locateBinarySearch() {
    if ((int)lastPage - (int)firstPage < 0)
      located();
    else
      readMetadata(locateCurrentPage());
  }

  void locateGreaterThan() {
    firstPage = locateCurrentPage() + 1;
    locateBinarySearch();
  }

  void locateLessThan() {
    lastPage = locateCurrentPage() - 1;
    locateBinarySearch();
  }

  void locateReadDone() {
    if (metadata.magic == PERSISTENT_MAGIC)
      crcPage(locateCurrentPage());
    else
      locateLessThan();
  }

  void locateCrcDone(uint16_t crc) {
    if (crc == metadata.crc)
      locateGreaterThan();
    else
      locateLessThan();
  }

  /* Locate log beginning and ending */
  void locateStart() {
    metaState = META_LOCATE;
    firstPage = firstVolumePage();
    lastPage = lastVolumePage() - 1;
    setReadPage(firstPage);
    // We set the valid page to the largest valid page found. But there
    // may be no valid pages, so we need to set the default value here.
    setWritePage(firstPage); 
    locateBinarySearch();
  }

  /* ------------------------------------------------------------------ */
  /* Append								*/
  /* ------------------------------------------------------------------ */

  void appendContinue() {
    uint8_t *buf = s[client].buf;
    at45pageoffset_t offset = s[client].woffset, count;
    
    if (len == 0)
      {
	endRequest(SUCCESS);
	return;
      }

    if (s[client].wpage == lastVolumePage())
      {
	endRequest(ESIZE);
	return;
      }

    if (offset + len <= PAGE_SIZE)
      count = len;
    else
      count = PAGE_SIZE - offset;
    s[client].buf += count;
    len -= count;
    s[client].woffset = offset + count;

    call At45db.write(s[client].wpage, offset, buf, count);
  }
  
  void appendWriteDone() {
    if (s[client].woffset == PAGE_SIZE) /* Time to write metadata */
      wmetadataStart();
    else
      endRequest(SUCCESS);
  }

  void appendMetadataDone(error_t ok) { // metadata of previous page flushed
    if (ok != SUCCESS)
      endRequest(FAIL);
    else
      {
	/* Setup metadata in case we overflow this page too */
	metadata.flags = 0;
	appendContinue();
      }
  }

  void appendStart() {
    /* Set lastRecordOffset in case we need to write metadata (see
       wmetadataStart) */
    metadata.lastRecordOffset = s[client].woffset;
    metadata.flags = F_LASTVALID;
    appendContinue();
  }

  /* ------------------------------------------------------------------ */
  /* Sync								*/
  /* ------------------------------------------------------------------ */

  void syncStart() {
    if (s[client].woffset == 0) /* we can't lose any writes */
      endRequest(SUCCESS);
    else
      {
	metadata.flags = F_SYNC | F_LASTVALID;
	metadata.lastRecordOffset = s[client].woffset;
	wmetadataStart();
      }
  }

  void syncMetadataDone(error_t ok) {
    endRequest(ok);
  }

  /* ------------------------------------------------------------------ */
  /* Write block metadata						*/
  /* ------------------------------------------------------------------ */

  void wmetadataStart() {
    /* The caller ensures that metadata is set correctly. */
    metaState = META_WRITE;
    call At45db.computeCrc(s[client].wpage, 0, PAGE_SIZE, 0);

    /* We move to the next page now. If writing the metadata fails, we'll
       simply leave the invalid page in place. Trying to recover seems
       complicated, and of little benefit (note that in practice, At45dbC
       shuts down after a failed write, so nothing is really going to
       happen after that anyway). */
    setWritePage(s[client].wpage + 1);
  }

  void wmetadataCrcDone(uint16_t crc) {
    uint8_t i, *md;

    metadata.magic = PERSISTENT_MAGIC;

    // Include metadata in crc
    md = (uint8_t *)&metadata;
    for (i = 0; i < offsetof(nx_struct pageinfo, crc); i++)
      crc = crcByte(crc, md[i]);
    metadata.crc = crc;

    // And save it
    writeMetadata(s[client].wpage - 1);
  }

  void wmetadataWriteDone() {
    metaState = META_IDLE;
    if (s[client].request == S_SYNC)
      call At45db.sync(s[client].wpage - 1);
    else
      call At45db.flush(s[client].wpage - 1);
  }

  /* ------------------------------------------------------------------ */
  /* Read 								*/
  /* ------------------------------------------------------------------ */

  void readContinue() {
    uint8_t *buf = s[client].buf;
    at45pageoffset_t offset = s[client].roffset, count;
    at45pageoffset_t end = s[client].rend;
    
    if (len == 0)
      {
	endRequest(SUCCESS);
	return;
      }

    if (s[client].rpage == s[client].wpage)
      end = s[client].woffset;

    if (offset == end)
      {
	if (s[client].rpage + 1 == lastVolumePage() ||
	    s[client].rpage == s[client].wpage)
	  endRequest(ESIZE);
	else
	  rmetadataStart();
	return;
      }

    if (offset + len <= end)
      count = len;
    else
      count = end - offset;

    s[client].buf += count;
    len -= count;
    s[client].roffset = offset + count;

    call At45db.read(s[client].rpage, offset, buf, count);
  }

  void readStart() {
    readContinue();
  }

  /* ------------------------------------------------------------------ */
  /* Read block metadata						*/
  /* ------------------------------------------------------------------ */

  void rmetadataStart() {
    metaState = META_READ;
    readMetadata(s[client].rpage + 1);
  }

  void rmetadataReadDone() {
    if (metadata.magic == PERSISTENT_MAGIC)
      crcPage(s[client].rpage + 1);
    else
      endRequest(ESIZE);
  }

  void rmetadataCrcDone(uint16_t crc) {
    if (crc == metadata.crc)
      {
	metaState = META_IDLE;
	s[client].rpage++;
	s[client].roffset = 0;
	s[client].rend =
	  metadata.flags & F_SYNC ? metadata.lastRecordOffset : PAGE_SIZE;
	readContinue();
      }
    else
      endRequest(ESIZE);
  }

  /* ------------------------------------------------------------------ */
  /* Dispatch HAL operations to current user op				*/
  /* ------------------------------------------------------------------ */

  event void At45db.eraseDone(error_t error) {
    if (client != NO_CLIENT)
      if (error != SUCCESS)
	endRequest(error);
      else
	eraseContinue();
  }

  event void At45db.writeDone(error_t error) {
    if (client != NO_CLIENT)
      if (error != SUCCESS)
	endRequest(error);
      else
	switch (metaState)
	  {
	  case META_WRITE: wmetadataWriteDone(); break;
	  case META_IDLE: appendWriteDone(); break;
	  }
  }

  event void At45db.syncDone(error_t error) {
    if (client != NO_CLIENT)
      syncMetadataDone(error);
  }

  event void At45db.flushDone(error_t error) {
    if (client != NO_CLIENT)
      appendMetadataDone(error);
  }

  event void At45db.readDone(error_t error) {
    if (client != NO_CLIENT)
      if (error != SUCCESS)
	endRequest(error);
      else
	switch (metaState)
	  {
	  case META_LOCATE: locateReadDone(); break;
	  case META_LOCATELAST: locateLastReadDone(); break;
	  case META_READ: rmetadataReadDone(); break;
	  case META_IDLE: readContinue(); break;
	  }					    
  }

  event void At45db.computeCrcDone(error_t error, uint16_t crc) {
    if (client != NO_CLIENT)
      if (error != SUCCESS)
	endRequest(error);
      else
	switch (metaState)
	  {
	  case META_LOCATE: locateCrcDone(crc); break;
	  case META_LOCATELAST: locateLastCrcDone(crc); break;
	  case META_WRITE: wmetadataCrcDone(crc); break;
	  case META_READ: rmetadataCrcDone(crc); break;
	  }
  }

  default event void LinearWrite.appendDone[logstorage_t logId](void* buf, storage_len_t l, error_t error) { }
  default event void LinearWrite.eraseDone[logstorage_t logId](error_t error) { }
  default event void LinearWrite.syncDone[logstorage_t logId](error_t error) { }
  default event void LinearRead.readDone[logstorage_t logId](void* buf, storage_len_t l, error_t error) { }
  default event void LinearRead.seekDone[logstorage_t logId](error_t error) {}

  default command at45page_t At45dbVolume.remap[logstorage_t logId](at45page_t volumePage) {return 0;}
  default command storage_len_t At45dbVolume.volumeSize[logstorage_t logId]() {return 0;}
  default async command error_t Resource.request[logstorage_t logId]() {return SUCCESS;}
  default async command void Resource.release[logstorage_t logId]() { }
}
