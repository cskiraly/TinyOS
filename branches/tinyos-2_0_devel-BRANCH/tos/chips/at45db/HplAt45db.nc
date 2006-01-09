/*									tab:4
 * Copyright (c) 2002-2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
/**
 * Low-level AT45DB operations.
 *
 * @author David Gay
 */

#include "HplAt45db.h"

interface HplAt45db {
  command void waitIdle();
  event void waitIdleDone();

  command void waitCompare();
  event void waitCompareDone(bool compareOk);

  command void fill(uint8_t cmd, at45page_t page);
  event void fillDone();

  command void flush(uint8_t cmd, at45page_t page);
  event void flushDone();

  command void compare(uint8_t cmd, at45page_t page);
  event void compareDone();

  command void erase(uint8_t cmd, at45page_t page);
  event void eraseDone();

  command void read(uint8_t cmd, at45page_t page, at45pageoffset_t offset,
		    uint8_t *data, at45pageoffset_t count);
  event void readDone();

  command void crc(uint8_t cmd, at45page_t page, at45pageoffset_t offset,
		   at45pageoffset_t count, uint16_t baseCrc);
  event void crcDone(uint16_t computedCrc);

  command void write(uint8_t cmd, at45page_t page, at45pageoffset_t offset,
		     uint8_t *data, at45pageoffset_t count);
  event void writeDone();
}
