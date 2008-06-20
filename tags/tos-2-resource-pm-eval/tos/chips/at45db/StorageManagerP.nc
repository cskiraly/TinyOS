/*
 * Copyright (c) 2006 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */

/**
 * Private component for reporting on an AT45DB's volume table.
 *
 * @author: David Gay <dgay@acm.org>
 */

module StorageManagerP {
  provides interface At45dbVolume[volume_id_t volid];
}
implementation {
  command at45page_t At45dbVolume.remap[volume_id_t volid](at45page_t volumePage) {
    switch (volid)
      {
#define VB(id, base) case id: return volumePage + base;
#include "StorageVolumes.h"
      default: return AT45_MAX_PAGES;
      }
  }

  command storage_len_t At45dbVolume.volumeSize[volume_id_t volid]() {
    switch (volid)
      {
#define VS(id, size) case id: return (storage_addr_t)size << AT45_PAGE_SIZE_LOG2;
#include "StorageVolumes.h"
      default: return 0;
      }
  }
}