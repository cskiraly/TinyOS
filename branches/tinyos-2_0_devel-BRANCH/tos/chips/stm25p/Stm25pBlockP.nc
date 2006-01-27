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
 * @author Jonathan Hui <jhui@archedrock.com>

 * $Revision: 1.1.2.2 $
 * $Date: 2006-01-27 06:56:19 $
 */

module Stm25pBlockP {

  provides interface BlockRead as Read[ storage_block_t block ];
  provides interface BlockWrite as Write[ storage_block_t block ];
  provides interface StorageMap[ storage_block_t block ];

  uses interface Stm25pSector as Sector[ storage_block_t block ];
  uses interface Resource as ClientResource[ storage_block_t block ];
  uses interface Leds;

}

implementation {

  enum {
    NUM_BLOCKS = uniqueCount( "Stm25p.Block" ),
  };
  
  typedef enum {
    S_IDLE,
    S_READ,
    S_VERIFY,
    S_CRC,
    S_WRITE,
    S_COMMIT,
    S_ERASE,
  } stm25p_block_req_t;
  
  typedef struct stm25p_block_state_t {
    storage_addr_t addr;
    void* buf;
    storage_len_t len;
    stm25p_block_req_t req;
  } stm25p_block_state_t;
  
  stm25p_block_state_t m_block_state[ NUM_BLOCKS ];
  stm25p_block_state_t m_req;
  
  error_t newRequest( uint8_t client );
  void signalDone( storage_block_t b, uint16_t crc, error_t error );

  command storage_addr_t StorageMap.getPhysicalAddress[ storage_block_t b ]( storage_addr_t addr ) {
    return call Sector.getPhysicalAddress[ b ]( addr );
  }

  command error_t Read.read[ storage_block_t b ]( storage_addr_t addr,
						  void* buf,
						  storage_len_t len ) {
    m_req.req = S_READ;
    m_req.addr = addr;
    m_req.buf = buf;
    m_req.len = len;
    return newRequest( b );
  }
  
  command error_t Read.verify[ storage_block_t b ]() {
    m_req.req = S_VERIFY;
    return newRequest( b );
  }
  
  command error_t Read.computeCrc[ storage_block_t b ]( storage_addr_t addr,
							storage_len_t len ) {
    m_req.req = S_CRC;
    m_req.addr = addr;
    m_req.len = len;
    return newRequest( b );
  }
  
  command error_t Write.write[ storage_block_t b ]( storage_addr_t addr, 
						    void* buf, 
						    uint16_t len ) {
    m_req.req = S_WRITE;
    m_req.addr = addr;
    m_req.buf = buf;
    m_req.len = len;
    return newRequest( b );
  }
  
  command error_t Write.commit[ storage_block_t b ]() {
    m_req.req = S_COMMIT;
    return newRequest( b );
  }
  
  command error_t Write.erase[ storage_block_t b ]() {
    m_req.req = S_ERASE;
    return newRequest( b );
  }
  
  error_t newRequest( storage_block_t client ) {

    if ( m_block_state[ client ].req != S_IDLE )
      return FAIL;

    call ClientResource.request[ client ]();
    m_block_state[ client ] = m_req;

    return SUCCESS;

  }

  event void ClientResource.granted[ storage_block_t b ]() {

    switch( m_block_state[ b ].req ) {
    case S_READ:
      call Sector.read[ b ]( m_block_state[ b ].addr, m_block_state[ b ].buf, 
			     m_block_state[ b ].len );
      break;
    case S_CRC:
      call Sector.computeCrc[ b ]( 0, m_block_state[ b ].addr, 
				   m_block_state[ b ].len );
      break;
    case S_WRITE:
      call Sector.write[ b ]( m_block_state[ b ].addr, m_block_state[ b ].buf, 
			      m_block_state[ b ].len );
      break;
    case S_ERASE:
      call Sector.erase[ b ]( 0, call Sector.getNumSectors[ b ]() );
      break;
    case S_COMMIT: case S_VERIFY:
      signalDone( b, 0, SUCCESS );
      break;
    case S_IDLE:
      break;
    }

  }
  
  event void Sector.readDone[ storage_block_t b ]( stm25p_addr_t addr, 
						   uint8_t* buf, 
						   stm25p_len_t len, 
						   error_t error ) {
    signalDone( b, 0, error );
  }
  
  event void Sector.writeDone[ storage_block_t b ]( stm25p_addr_t addr, 
						    uint8_t* buf, 
						    stm25p_len_t len, 
						    error_t error ) {
    signalDone( b, 0, error );
  }
  
  event void Sector.eraseDone[ storage_block_t b ]( uint8_t sector,
						    uint8_t num_sectors,
						    error_t error ) {
    signalDone( b, 0, error );
  }
  
  event void Sector.computeCrcDone[ storage_block_t b ]( stm25p_addr_t addr, 
							 stm25p_len_t len,
							 uint16_t crc,
							 error_t error ) {
    signalDone( b, crc, error );
  }

  void signalDone( storage_block_t b, uint16_t crc, error_t error ) {

    stm25p_block_req_t req = m_block_state[ b ].req;    

    call ClientResource.release[ b ]();
    m_block_state[ b ].req = S_IDLE;
    switch( req ) {
    case S_READ:
      signal Read.readDone[ b ]( m_block_state[ b ].addr, 
				 m_block_state[ b ].buf,
				 m_block_state[ b ].len, error );  
      break;
    case S_VERIFY:
      signal Read.verifyDone[ b ]( error );
      break;
    case S_CRC:
      signal Read.computeCrcDone[ b ]( m_block_state[ b ].addr, 
				       m_block_state[ b ].len, crc, error );
      break;
    case S_WRITE:
      signal Write.writeDone[ b ]( m_block_state[ b ].addr, 
				   m_block_state[ b ].buf,
				   m_block_state[ b ].len, error );
      break;
    case S_COMMIT:
      signal Write.commitDone[ b ]( error );
      break;
    case S_ERASE:
      signal Write.eraseDone[ b ]( error );
      break;
    case S_IDLE:
      break;
    }

  }

  default event void Read.readDone[ storage_block_t b ]( storage_addr_t addr, void* buf, uint16_t len, error_t error ) {}
  default event void Read.computeCrcDone[ storage_block_t b ]( storage_addr_t addr, storage_len_t len, uint16_t crc, error_t error ) {}
  default event void Read.verifyDone[ storage_block_t b ]( error_t error ) {}
  default event void Write.writeDone[ storage_block_t b ]( storage_addr_t addr, void* buf, uint16_t len, error_t error ) {}
  default event void Write.eraseDone[ storage_block_t b ]( error_t error ) {}
  default event void Write.commitDone[ storage_block_t b ]( error_t error ) {}

  default command storage_addr_t Sector.getPhysicalAddress[ storage_block_t b ]( storage_addr_t addr ) { return 0xffffffff; }
  default command uint8_t Sector.getNumSectors[ storage_block_t b ]() { return 0; }
  default command error_t Sector.read[ storage_block_t b ]( stm25p_addr_t addr, uint8_t* buf, stm25p_len_t len ) { return FAIL; }
  default command error_t Sector.write[ storage_block_t b ]( stm25p_addr_t addr, uint8_t* buf, stm25p_len_t len ) { return FAIL; }
  default command error_t Sector.erase[ storage_block_t b ]( uint8_t sector, uint8_t num_sectors ) { return FAIL; }
  default command error_t Sector.computeCrc[ storage_block_t b ]( uint16_t crc, storage_addr_t addr, storage_len_t len ) { return FAIL; }
  default async command error_t ClientResource.request[ storage_block_t b ]() { return FAIL; }
  default async command void ClientResource.release[ storage_block_t b ]() {}

}

