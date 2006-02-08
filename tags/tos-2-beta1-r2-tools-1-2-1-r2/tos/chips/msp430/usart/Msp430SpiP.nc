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
 * $Revision: 1.1.2.5 $
 * $Date: 2006-01-29 04:57:30 $
 *
 * @author Jonathan Hui <jhui@archedrock.com>
 */


generic module Msp430SpiP() {

  provides interface Init;
  provides interface Resource;
  provides interface SpiByte;
  provides interface SpiPacket[ uint8_t id ];

  uses interface Resource as UsartResource;
  uses interface ArbiterInfo;
  uses interface HplMsp430Usart as HplUsart;
}

implementation {

  enum {
    SPI_ATOMIC_SIZE = 2,
  };

  norace uint8_t* m_tx_buf;
  norace uint8_t* m_rx_buf;
  norace uint16_t m_len;
  norace uint16_t m_pos;
  norace uint8_t client;
  bool isOwner;

  void signalDone();
  task void signalDone_task();

  command error_t Init.init() {
    atomic isOwner = FALSE;
    return SUCCESS;
  }

  async command error_t Resource.immediateRequest() {
    error_t result = call UsartResource.immediateRequest();
    if ( result == SUCCESS )
      atomic isOwner = TRUE;
      call HplUsart.setModeSPI();
    return result;
  }

  async command error_t Resource.request() {
    return call UsartResource.request();
  }

  async command uint8_t Resource.getId() {
    return call UsartResource.getId();
  }

  async command void Resource.release() {
    atomic isOwner = FALSE;
    call UsartResource.release();
  }

  event void UsartResource.granted() {
    atomic isOwner = TRUE;
    call HplUsart.setModeSPI();
    signal Resource.granted();
  }

  async command error_t SpiByte.write( uint8_t tx, uint8_t* rx ) {
    bool owner;
    atomic owner = isOwner;
    if (owner != TRUE) return FAIL;
    call HplUsart.disableRxIntr();
    call HplUsart.tx( tx );
    while( !call HplUsart.isRxIntrPending() );
    *rx = call HplUsart.rx();
    call HplUsart.enableRxIntr();
    return SUCCESS;
  }

  default event void Resource.granted() {}

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

  async command error_t SpiPacket.send[ uint8_t id ]( uint8_t* tx_buf,
                                                      uint8_t* rx_buf,
                                                      uint16_t len ) {

    bool owner;
    atomic owner = isOwner;
    if (owner != TRUE) return FAIL;

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
    bool owner;
    atomic owner = isOwner;
    if (owner != TRUE) return;
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
    signal SpiPacket.sendDone[ client ]( m_tx_buf, m_rx_buf, m_len, SUCCESS );
  }

  async event void HplUsart.txDone() {}

  default async event void SpiPacket.sendDone[ uint8_t id ]( uint8_t* tx_buf, uint8_t* rx_buf, uint16_t len, error_t error ) {}

}
