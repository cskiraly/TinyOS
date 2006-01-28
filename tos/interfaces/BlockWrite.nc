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
 * Write interface for the block storage abstraction described in
 * TEP103.
 *
 * @author Jonathan Hui <jhui@archedrock.com>
 * @version $Revision: 1.1.2.7 $ $Date: 2006-01-28 01:27:19 $
 */

#include "Storage.h"

interface BlockWrite {
  
  /**
   * Initiate a write operation within a given volume. On SUCCESS, the
   * <code>writeDone</code> event will signal completion of the
   * operation.
   * 
   * @param addr starting address to begin write.
   * @param buf buffer to write data from.
   * @param len number of bytes to write.
   * @return SUCCESS if the request was accepted, FAIL otherwise.
   */
  command error_t write( storage_addr_t addr, void* buf, storage_len_t len );

  /**
   * Signals the completion of a read operation. However, data is not
   * guaranteed to survive a power-cycle unless a commit operation has
   * been completed.
   *
   * @param addr starting address of write.
   * @param buf buffer that written data was read from.
   * @param len number of bytes rwrite.
   * @param error notification of how the operation went.
   */
  event void writeDone( storage_addr_t addr, void* buf, storage_len_t len, 
			error_t error );
  
  /**
   * Initiate an erase operation. On SUCCESS, the
   * <code>eraseDone</code> event will signal completion of the
   * operation.
   *
   * @return SUCCESS if the request was accepted, FAIL otherwise.
   */
  command error_t erase();
  
  /**
   * Signals the completion of an erase operation.
   *
   * @param error notification of how the operation went.
   */
  event void eraseDone( error_t error );

  /**
   * Initiate a commit operation and finialize any additional writes
   * to the volume. A verify operation from <code>BlockRead</code> can
   * be done to check if the data has been modified since. A commit
   * operation must be issued to ensure that data is stored in
   * non-volatile storage. On SUCCES, the <code>commitDone</code>
   * event will signal completion of the operation.
   *
   * @return SUCCESS if the request was accepted, FAIL otherwise.
   */
  command error_t commit();

  /**
   * Signals the completion of a commit operation. All written data is
   * flushed to non-volatile storage after this event.
   *
   * @param error notification of how the operation went.
   */
  event void commitDone( error_t error );
  
}
