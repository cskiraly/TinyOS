// $Id: ConfigStorageP.nc,v 1.1.2.2 2006-05-25 22:31:28 idgay Exp $

/*									tab:4
 * Copyright (c) 2002-2006 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */

/**
 * Private component of the AT45DB implementation of the config storage
 * abstraction.
 *
 * @author: David Gay <dgay@acm.org>
 */

#include "Storage.h"

module ConfigStorageP {
  provides {
    interface SplitControl[configstorage_t id];
    interface ConfigStorage[configstorage_t id];
  }
  uses {
    interface At45db;
    interface At45dbBlockConfig as BConfig[configstorage_t id];
    interface BlockRead[configstorage_t id];
    interface BlockWrite[configstorage_t id];
  }
}
implementation 
{
  /* A config storage is built on top of a block storage volume, with
     the block storage volume divided into two and the first 4 bytes of
     each half holding a (>0) version number. The valid half with the
     highest version number is the current version.

     Transactional behaviour is achieved by copying the current half
     into the other, then increment its version number. Writes then
     proceed in that new half until a commit, which just uses the 
     underlying BlockStorage commit's operation.

     Note: all of this depends on the ay45db's implementation of 
     BlockStorageP. It will not work over an arbitrary BlockStorageP
     implementation (additionally, it uses hooks in BlockStorageP to
     support the half-volume operation).
  */

  enum {
    S_STOPPED,
    S_STOP,
    S_MOUNT,
    S_CLEAN,
    S_DIRTY,
  };

  enum {
    N = uniqueCount(UQ_CONFIG_STORAGE),
    NO_CLIENT = 0xff,
  };

  uint8_t state[N];
  uint32_t lowVersion[N], highVersion[N];

  uint8_t client = NO_CLIENT;
  at45page_t nextPage;

  command error_t SplitControl.start[uint8_t id]() {
    /* Read version on both halves. Validate higher. Validate lower if
       higher invalid. Use lower if both invalid. */
    if (state[id] != S_STOPPED)
      return FAIL;

    state[id] = S_MOUNT;
    call BConfig.setFlip[id](FALSE);
    call BlockRead.read[id](0, &lowVersion[id], sizeof lowVersion[id]);

    return SUCCESS;
  }

  void mountReadDone(uint8_t id, error_t error) {
    if (error != SUCCESS)
      {
	state[id] = S_STOPPED;
	signal SplitControl.startDone[id](FAIL);
      }
    else if (!call BConfig.flipped[id]())
      {
	call BConfig.setFlip[id](TRUE);
	call BlockRead.read[id](0, &highVersion[id], sizeof highVersion[id]);
      }
    else
      {
	call BConfig.setFlip[id](highVersion[id] > lowVersion[id]);
	call BlockRead.verify[id]();
      }
  }

  void mountVerifyDone(uint8_t id, error_t error) {
    if (error != SUCCESS) // try the other half?
      {
	bool flipped = call BConfig.flipped[id]();

	if ((highVersion[id] > lowVersion[id]) == flipped)
	  {
	    call BConfig.setFlip[id](!flipped);
	    call BlockRead.verify[id]();
	    return;
	  }
	/* both halves bad, just declare success and use the current half :-) 
	   (we did need to verify to find the end-of-block) */
      }
    state[id] = S_CLEAN;
    signal SplitControl.startDone[id](SUCCESS);
  }

  command error_t SplitControl.stop[uint8_t id]() {
    return FAIL;
  }

  command error_t ConfigStorage.read[configstorage_t id](storage_addr_t addr, void* buf, storage_len_t len) {
    /* Read from current half using BlockRead */
    if (!(state[id] == S_CLEAN || state[id] == S_DIRTY))
      return FAIL;
    return call BlockRead.read[id](addr + sizeof(uint32_t), buf, len);
  }

  command error_t ConfigStorage.write[configstorage_t id](storage_addr_t addr, void* buf, storage_len_t len) {
    /* 1: If first write:
         copy to other half, increment version number, and flip.
       2: Write to current half using BlockWrite */

    if (!(state[id] == S_CLEAN || state[id] == S_DIRTY))
      return FAIL;
    return call BlockWrite.write[id](addr + sizeof(uint32_t), buf, len);
  }

  void copyCopyPageDone(error_t error);
  void writeContinue(error_t error);

  event bool BConfig.writeHook[configstorage_t id]() {
    if (state[id] == S_DIRTY) // no work if already dirty
      return FALSE;

    /* Time to do the copy, version update dance */
    client = id;
    nextPage = call BConfig.npages[id]();
    copyCopyPageDone(SUCCESS);

    return TRUE;
  }

  void copyCopyPageDone(error_t error) {
    if (error != SUCCESS)
      writeContinue(error);
    else if (nextPage == 0) // copy done
      {
	uint32_t *version;

	// Set version number
	if (call BConfig.flipped[client]())
	  {
	    lowVersion[client] = highVersion[client] + 1;
	    version = &lowVersion[client];
	  }
	else
	  {
	    highVersion[client] = lowVersion[client] + 1;
	    version = &highVersion[client];
	  }
	call At45db.write(call BConfig.remap[client](0), 0,
			  version, sizeof *version);
      }
    else
      {
	at45page_t from, to, npages = call BConfig.npages[client]();

	to = from = call BConfig.remap[client](--nextPage);
	if (call BConfig.flipped[client]())
	  to -= npages;
	else
	  to += npages;

	call At45db.copyPage(from, to);
      }
  }

  void copyWriteDone(error_t error) {
    if (error == SUCCESS)
      {
	call BConfig.setFlip[client](!call BConfig.flipped[client]());
	state[client] = S_DIRTY;
      }
    writeContinue(error);
  }

  void writeContinue(error_t error) {
    uint8_t id = client;

    client = NO_CLIENT;
    call BConfig.writeContinue[id](error);
  }

  command error_t ConfigStorage.commit[configstorage_t id]() {
    /* Call BlockWrite.commit */
    /* Could special-case attempt to commit clean block */
    return call BlockWrite.commit[id]();
  }

  void commitDone(configstorage_t id, error_t error) {
    if (error == SUCCESS)
      state[id] = S_CLEAN;
    signal ConfigStorage.commitDone[id](error);
  }

  event void BlockRead.readDone[configstorage_t id](storage_addr_t addr, void* buf, storage_len_t len, error_t error) {
    if (state[id] == S_MOUNT)
      mountReadDone(id, error);
    else
      signal ConfigStorage.readDone[id](addr - sizeof(uint32_t), buf, len, error);
  }

  event void BlockRead.verifyDone[configstorage_t id]( error_t error ) {
    mountVerifyDone(id, error);
  }

  event void BlockWrite.writeDone[configstorage_t id]( storage_addr_t addr, void* buf, storage_len_t len, error_t error ) {
    signal ConfigStorage.writeDone[id](addr - sizeof(uint32_t), buf, len, error);
  }

  event void BlockWrite.commitDone[configstorage_t id]( error_t error ) {
    commitDone(id, error);
  }

  event void At45db.writeDone(error_t error) {
    if (client != NO_CLIENT)
      copyWriteDone(error);
  }

  event void At45db.copyPageDone(error_t error) {
    if (client != NO_CLIENT)
      copyCopyPageDone(error);
  }

  event void BlockRead.computeCrcDone[configstorage_t id]( storage_addr_t addr, storage_len_t len, uint16_t crc, error_t error ) {}
  event void BlockWrite.eraseDone[configstorage_t id]( error_t error ) {}
  event void At45db.eraseDone(error_t error) {}
  event void At45db.syncDone(error_t error) {}
  event void At45db.flushDone(error_t error) {}
  event void At45db.readDone(error_t error) {}
  event void At45db.computeCrcDone(error_t error, uint16_t crc) {}

  default event void SplitControl.startDone[configstorage_t id](error_t error) { }
  default event void ConfigStorage.readDone[configstorage_t id](storage_addr_t addr, void* buf, storage_len_t len, error_t error) {}
  default event void ConfigStorage.writeDone[configstorage_t id](storage_addr_t addr, void* buf, storage_len_t len, error_t error) {}
  default event void ConfigStorage.commitDone[configstorage_t id](error_t error) {}

  default command void BConfig.setFlip[configstorage_t id](bool flip) {}
  default command bool BConfig.flipped[configstorage_t id]() {
    return FALSE;
  }
  default command void BConfig.writeContinue[configstorage_t id](error_t error) {}
  default command at45page_t BConfig.npages[configstorage_t id]() {
    return 0;
  }
  default command at45page_t BConfig.remap[configstorage_t id](at45page_t page) {
    return AT45_MAX_PAGES;
  }
  default command error_t BlockRead.read[configstorage_t id]( storage_addr_t addr, void* buf, storage_len_t len ) {
    return SUCCESS;
  }
  default command error_t BlockRead.verify[configstorage_t id]() {
    return SUCCESS;
  }
  default command error_t BlockWrite.write[configstorage_t id]( storage_addr_t addr, void* buf, storage_len_t len ) {
    return SUCCESS;
  }
  default command error_t BlockWrite.commit[configstorage_t id]() {
    return SUCCESS;
  }
}
