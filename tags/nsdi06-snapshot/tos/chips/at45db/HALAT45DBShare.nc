// $Id: HALAT45DBShare.nc,v 1.1.2.1 2005-02-09 18:34:01 idgay Exp $

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
/**
 * Provide simple multi-client access to HALAT45DB volumes:
 * - does request-response matching (per-volume), i.e., you only get events
 *   for commands on the volume you're using (normally only one user per
 *   volume)
 * - does page remapping so you can use volume-relative page numbers
 */
module HALAT45DBShare {
  provides interface HALAT45DB[volume_t volume];
  uses interface HALAT45DB as ActualAT45;
  uses interface AT45Remap;
}
implementation {
  enum {
    NCLIENTS = uniqueCount(UQ_STORAGE_VOLUME)
  };
  volume_t lastClient;

  // Read & write the client id. We special case the 1-client case to
  // eliminate the overhead (still costs 1 byte of ram, though)
  int setClient(volume_t client) {
    if (NCLIENTS != 1)
      {
	if (lastClient)
	  return FALSE;
	lastClient = client + 1;
      }
    return TRUE;
  }

  volume_t getClient() {
    volume_t id = 0;

    if (NCLIENTS != 1)
      {
	id = lastClient - 1;
	lastClient = 0;
      }

    return id;
  }

  inline at45page_t remap(at45page_t page) {
    if (NCLIENTS != 1)
      return call AT45Remap(lastClient, page);
    else
      return call AT45Remap(0, page);
  }

  /* Clear client if request failed. */
  result_t check(result_t requestOk) {
    if (requestOk != FAIL)
      return requestOk;
    lastClient = 0;
    return FAIL;
  }

  // Simply use the setClient, getClient functions to match requests &
  // responses. The inline reduces the overhead of this layer.
  inline command result_t HALAT45DB.write[volume_t client](at45page_t page, at45pageoffset_t offset,
							   void *data, at45pageoffset_t n) {
    if (!setClient(client))
      return FAIL;
    return check(call ActualAT45.write(remap(page), offset, data, n));
  }

  inline event result_t ActualAT45.writeDone(result_t result) {
    return signal HALAT45DB.writeDone[getClient()](result);
  }

  inline command result_t HALAT45DB.erase[volume_t client](at45page_t page, uint8_t eraseKind) {
    if (!setClient(client))
      return FAIL;
    return check(call ActualAT45.erase(remap(page), eraseKind));
  }

  inline event result_t ActualAT45.eraseDone(result_t result) {
    return signal HALAT45DB.eraseDone[getClient()](result);
  }

  inline command result_t HALAT45DB.sync[volume_t client](at45page_t page) {
    if (!setClient(client))
      return FAIL;
    return check(call ActualAT45.sync(page));
  }

  inline command result_t HALAT45DB.syncAll[volume_t client]() {
    if (!setClient(client))
      return FAIL;
    return check(call ActualAT45.syncAll());
  }

  inline event result_t ActualAT45.syncDone(result_t result) {
    return signal HALAT45DB.syncDone[getClient()](result);
  }

  inline command result_t HALAT45DB.flush[volume_t client](at45page_t page) {
    if (!setClient(client))
      return FAIL;
    return check(call ActualAT45.flush(remap(page)));
  }

  inline command result_t HALAT45DB.flushAll[volume_t client]() {
    if (!setClient(client))
      return FAIL;
    return check(call ActualAT45.flushAll());
  }

  inline event result_t ActualAT45.flushDone(result_t result) {
    return signal HALAT45DB.flushDone[getClient()](result);
  }

  inline command result_t HALAT45DB.read[volume_t client](at45page_t page, at45pageoffset_t offset,
							  void *data, at45pageoffset_t n) {
    if (!setClient(client))
      return FAIL;
    return check(call ActualAT45.read(remap(page), offset, data, n));
  }

  inline event result_t ActualAT45.readDone(result_t result) {
    return signal HALAT45DB.readDone[getClient()](result);
  }

  inline command result_t HALAT45DB.computeCrc[volume_t client](at45page_t page, at45pageoffset_t offset,
								at45pageoffset_t n) {
    if (!setClient(client))
      return FAIL;
    return check(call ActualAT45.computeCrc(remap(page), offset, n));
  }

  inline event result_t ActualAT45.computeCrcDone(result_t result, uint16_t crc) {
    return signal HALAT45DB.computeCrcDone[getClient()](result, crc);
  }
  
  default event result_t HALAT45DB.writeDone[volume_t client](result_t result) {
    return FAIL;
  }

  default event result_t HALAT45DB.eraseDone[volume_t client](result_t result) {
    return FAIL;
  }

  default event result_t HALAT45DB.syncDone[volume_t client](result_t result) {
    return FAIL;
  }

  default event result_t HALAT45DB.flushDone[volume_t client](result_t result) {
    return FAIL;
  }

  default event result_t HALAT45DB.readDone[volume_t client](result_t result) {
    return FAIL;
  }

  default event result_t HALAT45DB.computeCrcDone[volume_t client](result_t result, uint16_t crc) {
    return FAIL;
  }
}
