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
 *
 * $Revision: 1.1.2.2 $
 * $Date: 2006-01-20 01:36:05 $
 */

module CC2420SpiImplP {

  provides interface CC2420Fifo as Fifo[ uint8_t id ];
  provides interface CC2420Ram as Ram[ uint16_t id ];
  provides interface CC2420Register as Reg[ uint8_t id ];
  provides interface CC2420Strobe as Strobe[ uint8_t id ];

  uses interface SPIByte;
  uses interface SPIPacket;
  uses interface Leds;

}

implementation {

  norace uint16_t m_addr;

  async command cc2420_status_t Fifo.beginRead[ uint8_t addr ]( uint8_t* data, 
								uint8_t len ) {
    
    cc2420_status_t status;
    
    m_addr = addr | 0x40;
    
    call SPIByte.write( m_addr, &status );
    call Fifo.continueRead[ addr ]( data, len );
    
    return status;
    
  }

  async command error_t Fifo.continueRead[ uint8_t addr ]( uint8_t* data,
							   uint8_t len ) {
    call SPIPacket.send( NULL, data, len );
    return SUCCESS;
  }

  async command cc2420_status_t Fifo.write[ uint8_t addr ]( uint8_t* data, 
							    uint8_t len ) {

    uint8_t status;

    m_addr = addr;

    call SPIByte.write( m_addr, &status );
    call SPIPacket.send( data, NULL, len );

    return status;

  }

  async command cc2420_status_t Ram.read[ uint16_t addr ]( uint8_t offset,
							   uint8_t* data, 
							   uint8_t len ) {

    cc2420_status_t status;

    addr += offset;

    call SPIByte.write( addr | 0x80, &status );
    call SPIByte.write( ( ( addr >> 1 ) & 0xc0 ) | 0x20, &status );
    for ( ; len; len-- )
      call SPIByte.write( 0, data++ );

    return status;

  }

  async event void SPIPacket.sendDone( uint8_t* tx_buf, uint8_t* rx_buf, 
				       uint16_t len, error_t error ) {
    if ( m_addr & 0x40 )
      signal Fifo.readDone[ m_addr & ~0x40 ]( rx_buf, len, error );
    else
      signal Fifo.writeDone[ m_addr ]( tx_buf, len, error );
  }

  async command cc2420_status_t Ram.write[ uint16_t addr ]( uint8_t offset,
							    uint8_t* data, 
							    uint8_t len ) {

    cc2420_status_t status;

    addr += offset;

    call SPIByte.write( addr | 0x80, &status );
    call SPIByte.write( ( addr >> 1 ) & 0xc0, &status );
    for ( ; len; len-- )
      call SPIByte.write( *data++, &status );

    return status;

  }

  async command cc2420_status_t Reg.read[ uint8_t addr ]( uint16_t* data ) {

    cc2420_status_t status;
    uint8_t tmp;

    call SPIByte.write( addr | 0x40, &status );
    call SPIByte.write( 0, &tmp );
    *data = (uint16_t)tmp << 8;
    call SPIByte.write( 0, &tmp );
    *data |= tmp;

    return status;

  }

  async command cc2420_status_t Reg.write[ uint8_t addr ]( uint16_t data ) {

    cc2420_status_t status;

    call SPIByte.write( addr, &status );
    call SPIByte.write( data >> 8, &status );
    call SPIByte.write( data & 0xff, &status );

    return status;

  }

  async command cc2420_status_t Strobe.strobe[ uint8_t addr ]() {

    cc2420_status_t status;

    call SPIByte.write( addr, &status );

    return status;

  }

  default async event void Fifo.readDone[ uint8_t addr ]( uint8_t* rx_buf, uint8_t rx_len, error_t error ) {}
  default async event void Fifo.writeDone[ uint8_t addr ]( uint8_t* tx_buf, uint8_t tx_len, error_t error ) {}

}
