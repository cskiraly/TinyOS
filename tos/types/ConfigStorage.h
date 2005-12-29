// $Id: ConfigStorage.h,v 1.1.2.1 2005-12-29 17:45:23 idgay Exp $

/*									tab:2
 * "Copyright (c) 2000-2005 The Regents of the University  of California.  
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
 */

/*
 * @author: Jonathan Hui <jwhui@cs.berkeley.edu>
 */

#ifndef __CONFIG_STORAGE_H__
#define __CONFIG_STORAGE_H__

#include "Storage.h"

enum {
  CONFIG_MAX_STR_LEN = 32,
  CONFIG_MAX_ITEMS = 1L,
  CONFIG_INVALID_ID = 0xffff,
  CONFIG_INVALID_SIZE = 0xffff,
  CONFIG_INVALID_VER = 0xffff,
};

typedef struct {
  uint16_t id;        // unique id of block
  uint16_t size;      // size of block
} config_header_t;

typedef struct {
  char name[CONFIG_MAX_STR_LEN];
  uint16_t id;
} config_entry_t;

typedef struct {
  int16_t ver;
  int16_t crc;
} config_sector_header_t;

typedef uint16_t config_addr_t;
typedef uint8_t configstorage_t;

enum {
  CONFIG_ID_SIZE = CONFIG_MAX_ITEMS*sizeof(config_entry_t),
  CONFIG_DATA_ADDR = CONFIG_ID_SIZE+sizeof(config_sector_header_t),
  CONFIG_MAX_SIZE = 16L*1024L, //STM25P_SECTOR_SIZE - CONFIG_DATA_ADDR,
};


#endif
