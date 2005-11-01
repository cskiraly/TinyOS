// $Id: HALSTM25P.h,v 1.1.2.2 2005-06-07 20:05:35 jwhui Exp $

/*									tab:4
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

#ifndef __STM25P_H__
#define __STM25P_H__

#include "Storage.h"

enum {
  STM25P_PAGE_SIZE = 256,
  STM25P_SECTOR_SIZE_LOG2 = 16,
  STM25P_SECTOR_SIZE = 1L << STM25P_SECTOR_SIZE_LOG2,
  STM25P_NUM_SECTORS = 16,
  STM25P_POWEROFF_DELAY = 1024,
};

enum {
  STM25P_INVALID_SIG = 0xff,
  STM25P_INVALID_VOLUME_ID = 0xff,
  STM25P_INVALID_SECTOR = 0xff,
};

enum {
  STM25P_CMD_SIZE        = 1,
  STM25P_ADDR_SIZE       = 3,
  STM25P_FR_DUMMY_BYTES  = 1,
  STM25P_RES_DUMMY_BYTES = 3,
};

typedef struct stm25p_cmd_t {
  uint8_t cmd;
  uint8_t address : 2;
  uint8_t dummy : 2;
  bool transmit : 1;
  bool receive : 1;
  bool write : 1;
  bool reserved : 1;
} stm25p_cmd_t;

enum {                   // I, A, D, T, R
  STM25P_WREN      = 0,  // 1, 0, 0, 0, 0
  STM25P_WRDI      = 1,  // 1, 0, 0, 0, 0
  STM25P_RDSR      = 2,  // 1, 0, 0, 0, 1
  STM25P_WRSR      = 3,  // 1, 0, 0, 1, 0
  STM25P_READ      = 4,  // 1, 3, 0, 0, N
  STM25P_FAST_READ = 5,  // 1, 3, 1, 0, N
  STM25P_PP        = 6,  // 1, 3, 0, N, 0
  STM25P_SE        = 7,  // 1, 3, 0, 0, 0
  STM25P_BE        = 8,  // 1, 0, 0, 0, 0
  STM25P_DP        = 9,  // 1, 0, 0, 0, 0
  STM25P_RES       = 10, // 1, 0, 3, 0, 1
  STM25P_CRC       = 11, // 1, 3, 0, 0, 1
};

static const stm25p_cmd_t STM25P_CMDS[12] = {
  { cmd : 0x06, // STM25P_WREN
    address : 0,
    dummy : 0,
    transmit : FALSE,
    receive : FALSE,
    write : FALSE },
  { cmd : 0x04, // STM25P_WRDI
    address : 0,
    dummy : 0,
    transmit : FALSE,
    receive : FALSE,
    write : FALSE },
  { cmd : 0x05, // STM25P_RDSR
    address : 0,
    dummy : 0,
    transmit : FALSE,
    receive : TRUE,
    write : FALSE },
  { cmd : 0x01, // STM25P_WRSR
    address : 0,
    dummy : 0,
    transmit : TRUE,
    receive : FALSE,
    write : TRUE },
  { cmd : 0x03, // STM25P_READ
    address : STM25P_ADDR_SIZE,
    dummy : 0,
    transmit : FALSE,
    receive : TRUE,
    write : FALSE },
  { cmd : 0x0b, // STM25P_FAST_READ
    address : STM25P_ADDR_SIZE,
    dummy : STM25P_FR_DUMMY_BYTES,
    transmit : FALSE,
    receive : TRUE,
    write : FALSE },
  { cmd : 0x02, // STM25P_PP
    address : STM25P_ADDR_SIZE,
    dummy : 0,
    transmit : TRUE,
    receive : FALSE,
    write : TRUE },
  { cmd : 0xd8, // STM25P_SE
    address : STM25P_ADDR_SIZE,
    dummy : 0,
    transmit : FALSE,
    receive : FALSE,
    write : TRUE },
  { cmd : 0xc7, // STM25P_BE
    address : 0,
    dummy : 0,
    transmit : FALSE,
    receive : FALSE,
    write : TRUE },
  { cmd : 0xb9, // STM25P_DP
    address : 0,
    dummy : 0,
    transmit : FALSE,
    receive : FALSE,
    write : FALSE },
  { cmd : 0xab, // STM25P_RES
    address : 0,
    dummy : 3,
    transmit : FALSE,
    receive : TRUE,
    write : FALSE },
  { cmd : 0x03, // STM25P_CRC
    address : STM25P_ADDR_SIZE,
    dummy : 0,
    transmit : FALSE,
    receive : TRUE,
    write : FALSE },
};

typedef uint8_t  stm25p_status_t;
typedef uint32_t stm25p_addr_t;
typedef uint8_t  stm25p_sig_t;

typedef struct {
  volume_id_t volumeId;
} SectorMetadata;

typedef struct {
  SectorMetadata sector[STM25P_NUM_SECTORS];
  uint16_t crc;
} SectorTable;

enum {
  STM25P_INVALID_VERSION = 0xffff,
};

enum {
  STM25P_INVALID_ADDR = 0xffffffff,
};

enum {
  STORAGE_BLOCK_SIZE = STM25P_SECTOR_SIZE,
};

typedef stm25p_addr_t storage_addr_t;

#endif
