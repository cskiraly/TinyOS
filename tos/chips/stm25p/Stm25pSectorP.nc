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
 * @author Jonathan Hui <jhui@archedrock.com>
 * @version $Revision: 1.1.2.6 $ $Date: 2006-02-17 22:13:22 $
 */

#include <Stm25p.h>
#include <StorageVolumes.h>

module Stm25pSectorP {

  provides interface Init;
  provides interface Resource as ClientResource[ storage_volume_t volume ];
  provides interface Stm25pSector as Sector[ storage_volume_t volume ];
  provides interface Stm25pVolume as Volume[ storage_volume_t volume ];

  uses interface Resource as Stm25pResource[ storage_volume_t volume ];
  uses interface Resource as SpiResource;
  uses interface Stm25pSpi as Spi;
  uses interface Leds;

}

implementation {

  enum {
    NUM_VOLUMES = uniqueCount( "Stm25p.Volume" ),
    NO_CLIENT = 0xff,
    NOT_BOUND = 0xff,
  };

  typedef enum {
    S_IDLE,
    S_READ,
    S_WRITE,
    S_ERASE,
    S_CRC,
  } stm25p_sector_state_t;

  norace stm25p_sector_state_t m_state;

  norace storage_volume_t m_volumes[ NUM_VOLUMES ];

  norace storage_volume_t m_client;
  norace stm25p_addr_t m_addr;
  norace stm25p_len_t m_len;
  norace stm25p_len_t m_cur_len;
  norace uint8_t* m_buf;
  norace error_t m_error;
  norace uint16_t m_crc;

  void bindVolume();
  void signalDone( error_t error );
  task void signalDone_task();

  command error_t Init.init() {
    int i;
    for ( i = 0; i < NUM_VOLUMES; i++ )
      m_volumes[ i ] = NOT_BOUND;
    return SUCCESS;
  }

  async command error_t ClientResource.request[ storage_volume_t v ]() {
    return call Stm25pResource.request[ v ]();
  }

  async command error_t ClientResource.immediateRequest[ storage_volume_t v ]() {
    return FAIL;
  }

  async command void ClientResource.release[ storage_volume_t v ]() {
    if ( m_client == v ) {
      m_state = S_IDLE;
      m_client = NO_CLIENT;
      call SpiResource.release();
      call Stm25pResource.release[ v ]();
    }
  }

  event void Stm25pResource.granted[ storage_volume_t v ]() {
    m_client = v;
    call SpiResource.request();
  }

  event void SpiResource.granted() {
    if ( m_volumes[ m_client ] == NOT_BOUND )
      m_volumes[ m_client ] = signal Volume.getVolumeId[ m_client ]();
    signal ClientResource.granted[ m_client ]();
  }

  async command uint8_t ClientResource.getId[ storage_volume_t v ]() {
    return call Stm25pResource.getId[v]();
  }

  stm25p_addr_t physicalAddr( storage_volume_t v, stm25p_addr_t addr ) {
    return addr + ( (stm25p_addr_t)STM25P_VMAP[ m_volumes[ v ] ].base 
		    << STM25P_SECTOR_SIZE_LOG2 );
  }

  stm25p_len_t calcWriteLen( stm25p_addr_t addr ) {
    stm25p_len_t len = STM25P_PAGE_SIZE - ( addr & STM25P_PAGE_MASK );
    return ( m_cur_len < len ) ? m_cur_len : len;
  }

  command stm25p_addr_t Sector.getPhysicalAddress[ storage_volume_t v ]( stm25p_addr_t addr ) {
    return physicalAddr( v, addr );
  }
  
  command uint8_t Sector.getNumSectors[ storage_volume_t v ]() {
    return STM25P_VMAP[ m_volumes[ v ] ].size;
  }

  command error_t Sector.read[ storage_volume_t v ]( stm25p_addr_t addr, 
						     uint8_t* buf, 
						     stm25p_len_t len ) {
    
    if ( m_volumes[ v ] == NOT_BOUND )
      return FAIL;
    
    m_state = S_READ;
    m_addr = addr;
    m_buf = buf;
    m_len = len;

    return call Spi.read( physicalAddr( v, addr ), buf, len );

  }

  async event void Spi.readDone( stm25p_addr_t addr, uint8_t* buf, 
				 stm25p_len_t len, error_t error ) {
    signalDone( error );
  }

  command error_t Sector.write[ storage_volume_t v ]( stm25p_addr_t addr, 
						      uint8_t* buf, 
						      stm25p_len_t len ) {
    
    if ( m_volumes[ v ] == NOT_BOUND )
      return FAIL;

    m_state = S_WRITE;
    m_addr = addr;
    m_buf = buf;
    m_len = m_cur_len = len;

    return call Spi.pageProgram( physicalAddr( v, addr ), buf, 
				 calcWriteLen( addr ) );

  }
  
  async event void Spi.pageProgramDone( stm25p_addr_t addr, uint8_t* buf, 
					stm25p_len_t len, error_t error ) {
    addr += len;
    buf += len;
    m_cur_len -= len;
    if ( !m_cur_len )
      signalDone( SUCCESS );
    else
      call Spi.pageProgram( addr, buf, calcWriteLen( addr ) );
  }

  command error_t Sector.erase[ storage_volume_t v ]( uint8_t sector,
						      uint8_t num_sectors ) {
    
    if ( m_volumes[ v ] == NOT_BOUND )
      return FAIL;
    
    m_state = S_ERASE;
    m_addr = sector;
    m_len = num_sectors;
    m_cur_len = 0;
    
    return call Spi.sectorErase( STM25P_VMAP[m_volumes[v]].base + m_addr +
				 m_cur_len );
    
  }
  
  async event void Spi.sectorEraseDone( uint8_t sector, error_t error ) {
    if ( ++m_cur_len < m_len )
      call Spi.sectorErase( STM25P_VMAP[m_volumes[m_client]].base + m_addr +
			    m_cur_len );
    else
      signalDone( error );
  }
  
  command error_t Sector.computeCrc[ storage_volume_t v ]( uint16_t crc, 
							   stm25p_addr_t addr,
							   stm25p_len_t len ) {
    
    if ( m_volumes[ v ] == NOT_BOUND )
      return FAIL;
    
    m_state = S_CRC;
    m_addr = addr;
    m_len = len;

    return call Spi.computeCrc( crc, m_addr, m_len );
    
  }
  
  async event void Spi.computeCrcDone( uint16_t crc, stm25p_addr_t addr, 
				       stm25p_len_t len, error_t error ) {
    m_crc = crc;
    signalDone( SUCCESS );
  }
  
  async event void Spi.bulkEraseDone( error_t error ) {
    
  }
  
  void signalDone( error_t error ) {
    m_error = error;
    post signalDone_task();
  }
  
  task void signalDone_task() {
    switch( m_state ) {
    case S_IDLE:
      signal ClientResource.granted[ m_client ]();
      break;
    case S_READ:
      signal Sector.readDone[ m_client ]( m_addr, m_buf, m_len, m_error );
      break;
    case S_CRC:
      signal Sector.computeCrcDone[ m_client ]( m_addr, m_len,
						m_crc, m_error );
      break;
    case S_WRITE:
      signal Sector.writeDone[ m_client ]( m_addr, m_buf, m_len, m_error );
      break;
    case S_ERASE:
      signal Sector.eraseDone[ m_client ]( m_addr, m_len, m_error );
      break;
    }
  }

  default event void ClientResource.granted[ storage_volume_t v ]() {}
  default event void Sector.readDone[ storage_volume_t v ]( stm25p_addr_t addr, uint8_t* buf, stm25p_len_t len, error_t error ) {}
  default event void Sector.writeDone[ storage_volume_t v ]( stm25p_addr_t addr, uint8_t* buf, stm25p_len_t len, error_t error ) {}
  default event void Sector.eraseDone[ storage_volume_t v ]( uint8_t sector, uint8_t num_sectors, error_t error ) {}
  default event void Sector.computeCrcDone[ storage_volume_t v ]( stm25p_addr_t addr, stm25p_len_t len, uint16_t crc, error_t error ) {}
  default async event volume_id_t Volume.getVolumeId[ storage_volume_t v ]() { return 0xff; }

}

