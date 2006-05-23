/**
 * Copyright (c) 2005-2006 Arched Rock Corporation
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the Arched Rock Corporation nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE
 * ARCHED ROCK OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE
 *
 * Copyright (c) 2002-2006 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */

/**
 * Read interface for the log storage abstraction described in
 * TEP103.
 *
 * @author Jonathan Hui <jhui@archedrock.com>
 * @author David Gay
 * @version $Revision: 1.1.2.3 $ $Date: 2006-05-23 21:57:48 $
 */

#include "Storage.h"

interface LogRead {
  
  /**
   * Initiate a read operation from the current position  within a given log volume. 
   * On SUCCESS, the <code>readDone</code> event will signal completion of the
   * operation.
   * 
   * @param buf buffer to place read data.
   * @param len number of bytes to read.
   * @return SUCCESS if the request was accepted, FAIL otherwise.
   */
  command error_t read(void* buf, storage_len_t len);

  /**
   * Signals the completion of a read operation. The current read position is
   * advanced by <code>len</code> bytes.
   *
   * @param addr starting address of read.
   * @param buf buffer where read data was placed.
   * @param len number of bytes read (correct even in case of error).
   * @param error notification of how the operation went.
   */
  event void readDone(void* buf, storage_len_t len, error_t error);

  command uint32_t currentOffset();

  command error_t seek(uint32_t offset);
  event void seekDone(error_t error);
  
  /**
   * Report volume size in bytes. Note that use of <code>sync</code>,
   * failures and general overhead may reduce the number of bytes
   * available to the log.
   *
   * @return Volume size.
   */
  //command storage_len_t getSize();
}
