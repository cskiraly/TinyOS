// $Id: LogStorage.h,v 1.1.2.1 2005-06-07 20:05:35 jwhui Exp $

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

#ifndef __LOG_STORAGE_H__
#define __LOG_STORAGE_H__

typedef uint32_t log_len_t;
typedef uint32_t log_cookie_t;
typedef uint8_t logstorage_t;

typedef uint16_t log_block_addr_t;

typedef struct {
  log_cookie_t cookie;
} LogSectorHeader;

typedef struct {
  log_block_addr_t length : 12;
  log_block_addr_t flags  : 4;
} LogBlockHeader;

enum {
  LOG_BLOCK_ALLOCATED = 1 << 0,
  LOG_BLOCK_VALID = 1 << 1,
};

enum {
  LOG_BLOCK_MAX_LENGTH = 1 << 8,
  LOG_BLOCK_LENGTH_MASK = (1 << 12) - 1,
  LOG_BLOCK_FLAGS_MASK = 0xf,
  LOG_MAX_COOKIE = 0xffffffff,
};

#endif
