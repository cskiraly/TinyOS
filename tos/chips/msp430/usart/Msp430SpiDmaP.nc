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
 * @version $Revision: 1.1.2.7 $ $Date: 2006-10-13 17:29:29 $
 */


generic module Msp430SpiDmaP() {

  provides interface Resource[ uint8_t id ];
  provides interface ResourceConfigure[ uint8_t id ];
  provides interface SpiByte;
  provides interface SpiPacket[ uint8_t id ];

  uses interface Msp430DmaChannel as DmaChannel1;
  uses interface Msp430DmaChannel as DmaChannel2;
  uses interface Resource as UsartResource[ uint8_t id ];
  uses interface Msp430SpiConfigure[uint8_t id ];
  uses interface HplMsp430Usart as Usart;
  uses interface HplMsp430UsartInterrupts as UsartInterrupts;
  uses interface Leds;

}

implementation {

  MSP430REG_NORACE( IFG1 );

  uint8_t* m_tx_buf;
  uint8_t* m_rx_buf;
  uint16_t m_len;
  uint8_t m_client;
  uint8_t m_dump;

  void signalDone( error_t error );
  task void signalDone_task();

  async command error_t Resource.immediateRequest[ uint8_t id ]() {
    return call UsartResource.immediateRequest[ id ]();
  }

  async command error_t Resource.request[ uint8_t id ]() {
    return call UsartResource.request[ id ]();
  }

  async command error_t Resource.release[ uint8_t id ]() {
    return call UsartResource.release[ id ]();
  }

  async command void ResourceConfigure.configure[ uint8_t id ]() {
    call Usart.setModeSpi(call Msp430SpiConfigure.getConfig[id]());
  }

  async command void ResourceConfigure.unconfigure[ uint8_t id ]() {
  }

  event void UsartResource.granted[ uint8_t id ]() {
    signal Resource.granted[ id ]();
  }

  async command uint8_t Resource.isOwner[ uint8_t id ]() {
    return call UsartResource.isOwner[ id ]();
  }

  default async command error_t UsartResource.isOwner[ uint8_t id ]() { return FAIL; }
  default async command error_t UsartResource.request[ uint8_t id ]() { return FAIL; }
  default async command error_t UsartResource.immediateRequest[ uint8_t id ]() { return FAIL; }
  default async command error_t UsartResource.release[ uint8_t id ]() { return FAIL; }
  default async command msp430_spi_config_t* Msp430SpiConfigure.getConfig[uint8_t id]() {
    return &msp430_spi_default_config;
  }

  default event void Resource.granted[ uint8_t id ]() {}

  async command uint8_t SpiByte.write( uint8_t tx ) {

    call Usart.tx( tx );
    while( !call Usart.isRxIntrPending() );
    return call Usart.rx();

  }

  async command error_t SpiPacket.send[ uint8_t id ]( uint8_t* tx_buf,
						      uint8_t* rx_buf,
						      uint16_t len ) {

    uint16_t ctrl;

    atomic {
      m_client = id;
      m_tx_buf = tx_buf;
      m_rx_buf = rx_buf;
      m_len = len;
    }

    if ( rx_buf ) {
      ctrl = 0xcd4;
    }
    else {
      ctrl = 0x0d4;
      rx_buf = &m_dump;
    }

    if ( len ) {
      IFG1 &= ~( UTXIFG0 | URXIFG0 );
      call DmaChannel1.setupTransferRaw( ctrl, DMA_TRIGGER_USARTRX,
					 (uint16_t*)U0RXBUF_, rx_buf, len );
      call DmaChannel2.setupTransferRaw( 0x3d4, DMA_TRIGGER_USARTTX,
					 tx_buf, (uint16_t*)U0TXBUF_, len );
      IFG1 |= UTXIFG0;
    }
    else {
      post signalDone_task();
    }

    return SUCCESS;

  }

  task void signalDone_task() {
    atomic signalDone( SUCCESS );
  }

  async event void DmaChannel1.transferDone( error_t error ) {
    signalDone( error );
  }

  async event void DmaChannel2.transferDone( error_t error ) {}

  void signalDone( error_t error ) {
    signal SpiPacket.sendDone[ m_client ]( m_tx_buf, m_rx_buf, m_len, error );
  }

  async event void UsartInterrupts.txDone() {}
  async event void UsartInterrupts.rxDone( uint8_t data ) {}

  default async event void SpiPacket.sendDone[ uint8_t id ]( uint8_t* tx_buf, uint8_t* rx_buf, uint16_t len, error_t error ) {}

}
