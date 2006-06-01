// $Id: LogStorageC.nc,v 1.1.2.3 2006-06-01 16:53:13 idgay Exp $
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
 * Implementation of the block storage abstraction from TEP103 for the
 * Atmel AT45DB serial data flash.
 *
 * @author David Gay
 */

#include "Storage.h"

generic configuration LogStorageC(volume_id_t volid, bool circular) {
  provides {
    interface LogWrite;
    interface LogRead;
  }
}
implementation {
  enum {
    LOG_ID = unique(UQ_LOG_STORAGE),
    INTF_ID = LOG_ID << 1 | circular,
    RESOURCE_ID = unique(UQ_AT45DB)
  };
    
  components LogStorageP, WireLogStorageP, StorageManagerP, At45dbC;

  LogWrite = LogStorageP.LogWrite[INTF_ID];
  LogRead = LogStorageP.LogRead[INTF_ID];

  LogStorageP.At45dbVolume[LOG_ID] -> StorageManagerP.At45dbVolume[volid];
  LogStorageP.Resource[LOG_ID] -> At45dbC.Resource[RESOURCE_ID];
}
