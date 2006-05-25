// $Id: ConfigStorageC.nc,v 1.1.2.2 2006-05-25 22:31:28 idgay Exp $
/*
 * Copyright (c) 2005-2006 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */

/**
 * Implementation of the config storage abstraction from TEP103 for the
 * Atmel AT45DB serial data flash.
 *
 * @author David Gay
 */

#include "Storage.h"

generic configuration ConfigStorageC(volume_id_t volid) {
  provides {
    interface SplitControl;
    interface ConfigStorage;
  }
}
implementation {
  enum {
    CONFIG_ID = unique(UQ_CONFIG_STORAGE),
    BLOCK_ID = uniqueCount(UQ_BLOCK_STORAGE) + CONFIG_ID,
    RESOURCE_ID = unique(UQ_AT45DB)
  };
    
  components ConfigStorageP, WireConfigStorageP, StorageManagerP, At45dbC;
  components BlockStorageP, WireBlockStorageP;

  SplitControl = ConfigStorageP.SplitControl[CONFIG_ID];
  ConfigStorage = ConfigStorageP.ConfigStorage[CONFIG_ID];

  ConfigStorageP.BlockRead[CONFIG_ID] -> BlockStorageP.BlockRead[BLOCK_ID];
  ConfigStorageP.BlockWrite[CONFIG_ID] -> BlockStorageP.BlockWrite[BLOCK_ID];
  ConfigStorageP.BConfig[CONFIG_ID] -> BlockStorageP.BConfig[BLOCK_ID];

  BlockStorageP.At45dbVolume[BLOCK_ID] -> StorageManagerP.At45dbVolume[volid];
  BlockStorageP.Resource[BLOCK_ID] -> At45dbC.Resource[RESOURCE_ID];
}
