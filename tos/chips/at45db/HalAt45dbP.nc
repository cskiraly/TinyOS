// $Id: HalAt45dbP.nc,v 1.1.2.1 2005-12-29 18:06:54 idgay Exp $

/*									tab:4
 * "Copyright (c) 2000-2003 The Regents of the University  of California.  
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
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
includes crc;
includes HALAT45DB;
module HALAT45DBM {
  provides {
    interface StdControl;
    interface HALAT45DB;
  }
  uses {
    interface HPLAT45DB;
  }
}
implementation
{
#define CHECKARGS

#if 0
  uint8_t work[20];
  uint8_t woffset;

  void wdbg(uint8_t x) {
    work[woffset++] = x;
    if (woffset == sizeof work)
      woffset = 0;
  }
#else
#define wdbg(n)
#endif

  enum { // requests
    IDLE,
    R_READ,
    R_READCRC,
    R_WRITE,
    R_ERASE,
    R_SYNC,
    R_SYNCALL,
    R_FLUSH,
    R_FLUSHALL,
    BROKEN // Write failed. Fail all subsequent requests.
  };
  uint8_t request;
  uint8_t *reqBuf;
  at45pageoffset_t reqOffset, reqBytes;
  at45page_t reqPage;

  enum {
    P_READ,
    P_READCRC,
    P_WRITE,
    P_FLUSH,
    P_FILL,
    P_ERASE,
    P_COMPARE,
    P_COMPARE_CHECK
  };
  
  struct {
    at45page_t page;
    bool busy : 1;
    bool clean : 1;
    bool erased : 1;
    uint8_t unchecked : 2;
  } buffer[2];
  uint8_t selected; // buffer used by the current op
  uint8_t checking;
  bool flashBusy;

  // Select a command for the current buffer
#define OPN(n, name) ((n) ? name ## 1 : name ## 2)
#define OP(name) OPN(selected, name)

  command result_t StdControl.init() {
    request = IDLE;
    flashBusy = TRUE;
      
    // pretend we're on an invalid non-existent page
    buffer[0].page = buffer[1].page = AT45_MAX_PAGES;
    buffer[0].busy = buffer[1].busy = FALSE;
    buffer[0].clean = buffer[1].clean = TRUE;
    buffer[0].unchecked = buffer[1].unchecked = 0;
    buffer[0].erased = buffer[1].erased = FALSE;

    return SUCCESS;
  }
  
  command result_t StdControl.start() {
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }

  void flashIdle() {
    flashBusy = buffer[0].busy = buffer[1].busy = FALSE;
  }

  void requestDone(result_t result, uint16_t computedCrc);
  void handleRWRequest();

  task void taskSuccess() {
    requestDone(SUCCESS, 0, IDLE);
  }
  task void taskFail() {
    requestDone(FAIL, 0, IDLE);
  }

  void checkBuffer(uint8_t buf) {
    call HPLAT45DB.compare(OPN(buf, AT45_C_COMPARE_BUFFER), buffer[buf].page);
    checking = buf;
  }

  void flushBuffer() {
    call HPLAT45DB.flush(buffer[selected].erased ?
			 OP(AT45_C_QFLUSH_BUFFER) :
			 OP(AT45_C_FLUSH_BUFFER), 
			 buffer[selected].page);
  }

  event result_t HPLAT45DB.waitIdleDone() {
    flashIdle();
    // Eager compare - this steals the current command
#if 0
    if ((buffer[0].unchecked || buffer[1].unchecked) &&
	cmdPhase != P_COMPARE)
      checkBuffer(buffer[0].unchecked ? 0 : 1);
    else
#endif
      handleRWRequest();
    return SUCCESS;
  }

  event result_t HPLAT45DB.waitCompareDone(bool ok) {
    flashIdle();

    if (ok)
      buffer[checking].unchecked = 0;
    else if (buffer[checking].unchecked < 2)
      buffer[checking].clean = FALSE;
    else
      {
	requestDone(FAIL, 0, BROKEN);
	return SUCCESS;
      }
    handleRWRequest();
    return SUCCESS;
  }

  event result_t HPLAT45DB.readDone() {
    requestDone(SUCCESS, 0, IDLE);
    return SUCCESS;
  }

  event result_t HPLAT45DB.writeDone() {
    buffer[selected].clean = FALSE;
    buffer[selected].unchecked = 0;
    requestDone(SUCCESS, 0, IDLE);
    return SUCCESS;
  }

  event result_t HPLAT45DB.crcDone(uint16_t crc) {
    requestDone(SUCCESS, crc, IDLE);
    return SUCCESS;
  }

  event result_t HPLAT45DB.flushDone() {
    flashBusy = TRUE;
    buffer[selected].clean = buffer[selected].busy = TRUE;
    buffer[selected].unchecked++;
    buffer[selected].erased = FALSE;
    handleRWRequest();
    return SUCCESS;
  }

  event result_t HPLAT45DB.compareDone() {
    flashBusy = TRUE;
    buffer[checking].busy = TRUE;
    // The 10us wait makes old mica motes (Atmega 103) happy, for
    // some mysterious reason (w/o this wait, the first compare
    // always fail, even though the compare after the rewrite
    // succeeds...)
    TOSH_uwait(10);
    call HPLAT45DB.waitCompare();
    return SUCCESS;
  }

  event result_t HPLAT45DB.fillDone() {
    flashBusy = TRUE;
    buffer[selected].page = reqPage;
    buffer[selected].clean = buffer[selected].busy = TRUE;
    buffer[selected].erased = FALSE;
    handleRWRequest();
    return SUCCESS;
  }

  event result_t HPLAT45DB.eraseDone() {
    flashBusy = TRUE;
    // The buffer contains garbage, but we don't care about the state
    // of bits on this page anyway (if we do, we'll perform a 
    // subsequent write)
    buffer[selected].page = reqPage;
    buffer[selected].clean = TRUE;
    buffer[selected].erased = TRUE;
    requestDone(SUCCESS, 0, IDLE);
    return SUCCESS;
  }

  result_t syncOrFlushAll(uint8_t newReq);

  void handleRWRequest() {
    if (reqPage == buffer[selected].page)
      switch (request)
	{
	case R_ERASE:
	  switch (reqOffset)
	    {
	    case AT45_ERASE:
	      if (flashBusy)
		call HPLAT45DB.waitIdle();
	      else
		call HPLAT45DB.erase(AT45_C_ERASE_PAGE, reqPage);
	      break;
	    case AT45_PREVIOUSLY_ERASED:
	      // We believe the user...
	      buffer[selected].erased = TRUE;
	      /* Fallthrough */
	    case AT45_DONT_ERASE:
	      // The buffer contains garbage, but we don't care about the state
	      // of bits on this page anyway (if we do, we'll perform a 
	      // subsequent write)
	      buffer[selected].clean = TRUE;
	      requestDone(SUCCESS, 0, IDLE);
	      break;
	    }
	  break;

	case R_SYNC: case R_SYNCALL:
	  if (buffer[selected].clean && buffer[selected].unchecked)
	    {
	      checkBuffer(selected);
	      return;
	    }
	  /* fall through */
	case R_FLUSH: case R_FLUSHALL:
	  if (!buffer[selected].clean)
	    flushBuffer();
	  else if (request == R_FLUSH || request == R_SYNC)
	    post taskSuccess();
	  else
	    {
	      // Check for more dirty pages
	      uint8_t oreq = request;

	      request = IDLE;
	      syncOrFlushAll(oreq);
	    }
	  break;

	case R_READ:
	  if (buffer[selected].busy)
	    call HPLAT45DB.waitIdle();
	  else
	    call HPLAT45DB.read(OP(AT45_C_READ_BUFFER), 0, reqOffset,
				reqBuf, reqBytes);
	  break;

	case R_READCRC:
	  if (buffer[selected].busy)
	    call HPLAT45DB.waitIdle();
	  else
	    /* Hack: baseCrc was stored in reqBuf */
	    call HPLAT45DB.crc(OP(AT45_C_READ_BUFFER), 0, reqOffset, reqBytes,
			       (uint16_t)reqBuf);
	  break;

	case R_WRITE:
	  if (buffer[selected].busy)
	    call HPLAT45DB.waitIdle();
	  else
	    call HPLAT45DB.write(OP(AT45_C_WRITE_BUFFER), 0, reqOffset,
				 reqBuf, reqBytes);
	  break;
	}
    else if (!buffer[selected].clean)
      flushBuffer();
    else if (buffer[selected].unchecked)
      checkBuffer(selected);
    else
      {
	// just get the new page (except for erase)
	if (request == R_ERASE)
	  {
	    buffer[selected].page = reqPage;
	    handleRWRequest();
	  }
	else if (flashBusy)
	  call HPLAT45DB.waitIdle();
	else
	  call HPLAT45DB.fill(OP(AT45_C_FILL_BUFFER), reqPage);
      }
  }

  void requestDone(result_t result, uint16_t computedCrc, uint8_t newState) {
    uint8_t orequest = request;

    request = newState;
    switch (orequest)
      {
      case R_READ: signal HALAT45DB.readDone(result); break;
      case R_READCRC: signal HALAT45DB.computeCrcDone(result, computedCrc); break;
      case R_WRITE: signal HALAT45DB.writeDone(result); break;
      case R_SYNC: case R_SYNCALL: signal HALAT45DB.syncDone(result); break;
      case R_FLUSH: case R_FLUSHALL: signal HALAT45DB.flushDone(result); break;
      case R_ERASE: signal HALAT45DB.eraseDone(result); break;
      }
  }

  result_t newRequest(uint8_t req, at45page_t page,
		      at45pageoffset_t offset,
		      void *reqdata, at45pageoffset_t n) {
#ifdef CHECKARGS
    if (page >= AT45_MAX_PAGES || offset >= AT45_PAGE_SIZE || n == 0 ||
	n > AT45_PAGE_SIZE || offset + n > AT45_PAGE_SIZE)
      return FAIL;
#endif

    if (request != IDLE)
      return FAIL;
    request = req;

    reqBuf = reqdata;
    reqBytes = n;
    reqPage = page;
    reqOffset = offset;

    if (page == buffer[0].page)
      selected = 0;
    else if (page == buffer[1].page)
      selected = 1;
    else
      selected = !selected; // LRU with 2 buffers...

    handleRWRequest();
    
    return SUCCESS;
  }

  command result_t HALAT45DB.read(at45page_t page, at45pageoffset_t offset,
				   void *reqdata, at45pageoffset_t n) {
    return newRequest(R_READ, page, offset, reqdata, n);
  }

  command result_t HALAT45DB.computeCrc(at45page_t page,
					at45pageoffset_t offset,
					at45pageoffset_t n,
					uint16_t baseCrc) {
    /* This is a hack (store crc in reqBuf), but it saves 2 bytes of RAM */
    if (request == IDLE)
      reqBuf = (uint8_t *)baseCrc;
    return newRequest(R_READCRC, page, offset, NULL, n);
  }

  command result_t HALAT45DB.write(at45page_t page, at45pageoffset_t offset,
				    void *reqdata, at45pageoffset_t n) {
    return newRequest(R_WRITE, page, offset, reqdata, n);
  }


  command result_t HALAT45DB.erase(at45page_t page, uint8_t eraseKind) {
    return newRequest(R_ERASE, page, eraseKind, NULL, 0);
  }

  result_t syncOrFlush(at45page_t page, uint8_t newReq) {
    if (request != IDLE)
      return FAIL;
    request = newReq;

    if (buffer[0].page == page)
      selected = 0;
    else if (buffer[1].page == page)
      selected = 1;
    else
      {
	post taskSuccess();
	return SUCCESS;
      }

    buffer[selected].unchecked = 0;
    handleRWRequest();

    return SUCCESS;
  }

  command result_t HALAT45DB.sync(at45page_t page) {
    return syncOrFlush(page, R_SYNC);
  }

  command result_t HALAT45DB.flush(at45page_t page) {
    return syncOrFlush(page, R_FLUSH);
  }

  result_t syncOrFlushAll(uint8_t newReq) {
    if (request != IDLE)
      return FAIL;
    request = newReq;

    if (!buffer[0].clean)
      selected = 0;
    else if (!buffer[1].clean)
      selected = 1;
    else
      {
	post taskSuccess();
	return SUCCESS;
      }

    buffer[selected].unchecked = 0;
    handleRWRequest();

    return SUCCESS;
  }

  command result_t HALAT45DB.syncAll() {
    return syncOrFlushAll(R_SYNCALL);
  }

  command result_t HALAT45DB.flushAll() {
    return syncOrFlushAll(R_FLUSHALL);
  }
}
