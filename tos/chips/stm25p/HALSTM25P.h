// $Id: HALSTM25P.h,v 1.1.2.1 2005-02-09 01:45:52 jwhui Exp $

/*									tab:4
 * "Copyright (c) 2000-2004 The Regents of the University  of California.  
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

enum {
  STM25P_PAGE_SIZE = 256
};

enum {
  STM25P_INVALID_SIG = 0xff,
};

enum {
  STM25P_ADDR_SIZE       = 3,
  STM25P_FR_DUMMY_BYTES  = 1,
  STM25P_RES_DUMMY_BYTES = 3,
};

enum {
                           // I, A, D, T, R
  STM25P_WREN      = 0x06, // 1, 0, 0, 0, 0
  STM25P_WRDI      = 0x04, // 1, 0, 0, 0, 0
  STM25P_RDSR      = 0x05, // 1, 0, 0, 0, 1
  STM25P_WRSR      = 0x01, // 1, 0, 0, 1, 0
  STM25P_READ      = 0x03, // 1, 3, 0, 0, N
  STM25P_FAST_READ = 0x0b, // 1, 3, 1, 0, N
  STM25P_PP        = 0x02, // 1, 3, 0, N, 0
  STM25P_SE        = 0xd8, // 1, 3, 0, 0, 0
  STM25P_BE        = 0xc7, // 1, 0, 0, 0, 0
  STM25P_DP        = 0xb9, // 1, 0, 0, 0, 0
  STM25P_RES       = 0xab, // 1, 0, 3, 0, 1
  STM25P_CRC       = 0xff, // not really an instruction
};

typedef uint8_t  stm25p_status_t;
typedef uint32_t stm25p_addr_t;
typedef uint8_t  stm25p_sig_t;

#endif
