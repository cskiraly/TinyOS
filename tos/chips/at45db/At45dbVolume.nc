/*
 * Copyright (c) 2005-2006 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */

#include "At45db.h"

interface At45dbVolume {
  /* Returns AT45_MAX_PAGES for invalid request (out of volume) */
  command at45page_t remap(at45page_t volumePage);

  command storage_addr_t volumeSize();
}
