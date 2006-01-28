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
 */

/**
 * Read interface for the block storage abstraction described in
 * TEP103.
 *
 * @author Jonathan Hui <jhui@archedrock.com>
 * @version $Revision: 1.1.2.8 $ $Date: 2006-01-28 01:39:30 $
 */

#include "Storage.h"

interface BlockRead {
  
  /**
   * Initiate a read operation within a given volume. On SUCCESS, the
   * <code>readDone</code> event will signal completion of the
   * operation.
   * 
   * @param addr starting address to begin reading.
   * @param buf buffer to place read data.
   * @param len number of bytes to read.
   * @return SUCCESS if the request was accepted, FAIL otherwise.
   */
  command error_t read( storage_addr_t addr, void* buf, storage_len_t len );

  /**
   * Signals the completion of a read operation.
   *
   * @param addr starting address of read.
   * @param buf buffer where read data was placed.
   * @param len number of bytes read.
   * @param error notification of how the operation went.
   */
  event void readDone( storage_addr_t addr, void* buf, storage_len_t len, 
		       error_t error );
  
  /**
   * Initiate a verify operation to verify the integrity of the
   * data. This operation is only valid after a commit operation from
   * <code>BlockWrite</code> has been completed. On SUCCESS, the
   * <code>verifyDone</code> event will signal completion of the
   * operation.
   *
   * @return SUCCESS if the request was accepted, FAIL otherwise.
   */
  command error_t verify();
  
  /**
   * Signals the completion of a verify operation.
   *
   * @param error notification of how the operation went.
   */
  event void verifyDone( error_t error );
  
  /**
   * Initiate a crc computation. On SUCCESS, the
   * <code>computeCrcDone</code> event will signal completion of the
   * operation.
   *
   * @param addr starting address.
   * @param len the number of bytes to compute the crc over.
   * @return SUCCESS if the request was accepted, FAIL otherwise.
   */
  command error_t computeCrc( storage_addr_t addr, storage_len_t len );

  /**
   * Signals the completion of a crc computation.
   *
   * @param addr stating address.
   * @param len number of bytes the crc was computed over.
   * @param crc the resulting crc value.
   * @param error notification of how the operation went.
   */
  event void computeCrcDone( storage_addr_t addr, storage_len_t len,
			     uint16_t crc, error_t error );

}
