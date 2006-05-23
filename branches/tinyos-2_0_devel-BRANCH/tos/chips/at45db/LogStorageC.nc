// $Id: LogStorageC.nc,v 1.1.2.1 2006-05-23 21:57:02 idgay Exp $
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

generic configuration LogStorageC(volume_id_t volid) {
  provides {
    interface LogWrite as LinearWrite;
    interface LogRead as LinearRead;
    //interface LogWrite as CircularWrite;
    //interface LogRead as CircularRead;
  }
}
implementation {
  enum {
    LOG_ID = unique(UQ_LOG_STORAGE),
    RESOURCE_ID = unique(UQ_AT45DB)
  };
    
  components LogStorageP, WireLogStorageP, StorageManagerP, At45dbC;

  LinearWrite = LogStorageP.LinearWrite[LOG_ID];
  LinearRead = LogStorageP.LinearRead[LOG_ID];
  //CircularWrite = LogStorageP.CircularWrite[LOG_ID];
  //CircularRead = LogStorageP.CircularRead[LOG_ID];

  LogStorageP.At45dbVolume[LOG_ID] -> StorageManagerP.At45dbVolume[volid];
  LogStorageP.Resource[LOG_ID] -> At45dbC.Resource[RESOURCE_ID];
}
