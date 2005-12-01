/**
 * Copyright (c) 2005 Arched Rock Corporation
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
 * $ Revision: $
 * $ Date: $
 *
 * @author Jonathan Hui <jhui@archedrock.com>
 */


generic module Msp430SpiP() {

  provides interface Init;
  provides interface Resource[ uint8_t id ];
  provides interface SPIByte;
  provides interface SPIPacket[ uint8_t id ];
  
  uses interface Resource as UsartResource[ uint8_t id ];
  uses interface HplMsp430Usart as HplUsart;
  uses interface Leds;

}

implementation {

  enum {
    SPI_ATOMIC_SIZE = 2,
  };
  
  norace uint8_t* m_tx_buf;
  norace uint8_t* m_rx_buf;
  norace uint8_t m_len;
  norace uint8_t m_pos;
  norace uint8_t client;

  void signalDone();
  task void signalDone_task();

  command error_t Init.init() {
    return SUCCESS;
  }

  async command error_t Resource.immediateRequest[ uint8_t id ]() {
    error_t result = call UsartResource.immediateRequest[ id ]();
    if ( result == SUCCESS )
      call HplUsart.setModeSPI();
    return result;
  }

  async command error_t Resource.request[ uint8_t id ]() {
    return call UsartResource.request[ id ]();
  }

  async command void Resource.release[ uint8_t id ]() {
    call UsartResource.release[ id ]();
  }

  event void UsartResource.granted[ uint8_t id ]() {
    call HplUsart.setModeSPI();
    signal Resource.granted[ id ]();
  }

  async command error_t SPIByte.write( uint8_t tx, uint8_t* rx ) {

    call HplUsart.tx( tx );
    while( !call HplUsart.isRxIntrPending() );
    *rx = call HplUsart.rx();

    return SUCCESS;

  }

  default event void Resource.granted[ uint8_t id ]() {}

  void continueOp() {

    uint8_t end;
    uint8_t tmp;

    atomic {
      call HplUsart.tx( m_tx_buf ? m_tx_buf[ m_pos ] : 0 );

      end = m_pos + SPI_ATOMIC_SIZE;
      if ( end > m_len )
	end = m_len;
      
      while ( ++m_pos < end ) {
	while( !call HplUsart.isTxIntrPending() );
	call HplUsart.tx( m_tx_buf ? m_tx_buf[ m_pos ] : 0 );
	while( !call HplUsart.isRxIntrPending() );
	tmp = call HplUsart.rx();
	if ( m_rx_buf )
	  m_rx_buf[ m_pos - 1 ] = tmp;
      }
    }

  }

  async command error_t SPIPacket.send[ uint8_t id ]( uint8_t* tx_buf, 
						      uint8_t* rx_buf, 
						      uint8_t len ) {

    client = id;
    m_tx_buf = tx_buf;
    m_rx_buf = rx_buf;
    m_len = len;
    m_pos = 0;

    if ( len ) {
      call HplUsart.enableRxIntr();
      continueOp();
    }
    else {
      post signalDone_task();
    }

    return SUCCESS;

  }

  task void signalDone_task() {
    atomic signalDone();
  }

  async event void HplUsart.rxDone( uint8_t data ) {

    if ( m_rx_buf )
      m_rx_buf[ m_pos-1 ] = data;

    if ( m_pos < m_len )
      continueOp();
    else {
      call HplUsart.disableRxIntr();
      signalDone();
    }
    
  }
  
  void signalDone() {
    signal SPIPacket.sendDone[ client ]( m_tx_buf, m_rx_buf, m_len, SUCCESS );
  }
  
  async event void HplUsart.txDone() {}

  default async event void SPIPacket.sendDone[ uint8_t id ]( uint8_t* tx_buf, uint8_t* rx_buf, uint8_t len, error_t error ) {}

}
