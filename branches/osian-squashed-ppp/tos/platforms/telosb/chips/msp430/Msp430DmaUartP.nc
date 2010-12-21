/**
 * Copyright (c) 2005-2006 Arch Rock Corporation
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
 * - Neither the name of the Arch Rock Corporation nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE
 * ARCH ROCK OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE
 */

/**
 * @author Jonathan Hui <jhui@archrock.com>
 * @author Vlado Handziski <handzisk@tkn.tu-berlin.de>
 * @author Eric B. Decker <cire831@gmail.com>
 * @version $Revision: 1.7 $ $Date: 2008-06-04 05:31:15 $
 */

#include <Timer.h>
#include <Msp430Dma.h>

generic module Msp430DmaUartP() {

  provides interface Resource[ uint8_t id ];
  provides interface ResourceConfigure[ uint8_t id ];
  provides interface UartStream[ uint8_t id ];
  provides interface UartByte[ uint8_t id ];
  
  uses interface Resource as UsartResource[ uint8_t id ];
  uses interface Msp430UartConfigure[ uint8_t id ];
  uses interface HplMsp430Usart as Usart;
  uses interface HplMsp430UsartInterrupts as UsartInterrupts[ uint8_t id ];
  uses interface Counter<T32khz,uint16_t>;
  uses interface Leds;

  uses interface Msp430DmaControl as DmaControl;
  uses interface Msp430DmaChannel as DmaChannel;

  uses interface Alarm<T32khz, uint16_t> as RxAbort;
}

implementation {
  
  norace uint16_t m_tx_len, m_rx_len;
  norace uint8_t * COUNT_NOK(m_tx_len) m_tx_buf, * COUNT_NOK(m_rx_len) m_rx_buf;
  norace uint16_t m_tx_pos;
  norace uint8_t m_byte_time;
  norace uint8_t current_owner;
  bool m_rx_enabled;
  uint16_t m_rx_last_check, m_rx_last_delivery;
  
  async command error_t Resource.immediateRequest[ uint8_t id ]() {
    return call UsartResource.immediateRequest[ id ]();
  }

  async command error_t Resource.request[ uint8_t id ]() {
    return call UsartResource.request[ id ]();
  }

  async command uint8_t Resource.isOwner[ uint8_t id ]() {
    return call UsartResource.isOwner[ id ]();
  }

  async command error_t Resource.release[ uint8_t id ]() {
    if (call UsartResource.isOwner[id]() == FALSE)
      return FAIL;
    if ( m_rx_buf || m_tx_buf )
      return EBUSY;
    return call UsartResource.release[ id ]();
  }

  async command void ResourceConfigure.configure[ uint8_t id ]() {
    msp430_uart_union_config_t* config = call Msp430UartConfigure.getConfig[id]();
    m_byte_time = config->uartConfig.ubr / 2;
    call Usart.setModeUart(config);
    call Usart.enableIntr();
  }

  async command void ResourceConfigure.unconfigure[ uint8_t id ]() {
    call Usart.resetUsart(TRUE);
    call Usart.disableIntr();
    call Usart.disableUart();

    /* leave the usart in reset */
    //call Usart.resetUsart(FALSE); // this shouldn't be called.
  }

  event void UsartResource.granted[ uint8_t id ]() {
    signal Resource.granted[ id ]();
  }
  
  async command error_t UartStream.enableReceiveInterrupt[ uint8_t id ]() {
    if (call UsartResource.isOwner[id]() == FALSE)
      return FAIL;
    atomic {
      call Usart.enableRxIntr();
      m_rx_enabled = TRUE;
    }
    return SUCCESS;
  }
  
  async command error_t UartStream.disableReceiveInterrupt[ uint8_t id ]() {
    if (call UsartResource.isOwner[id]() == FALSE)
      return FAIL;
    atomic {
      call Usart.disableRxIntr();
      m_rx_enabled = FALSE;
    }
    return SUCCESS;
  }

  async command error_t UartStream.receive[ uint8_t id ]( uint8_t* buf, uint16_t len ) {
    if (call UsartResource.isOwner[id]() == FALSE)
      return FAIL;
    if ( len == 0 )
      return FAIL;
    atomic {
      if ( m_rx_buf )
	return EBUSY;
      m_rx_buf = buf;
      m_rx_len = len;
      current_owner = id;

      /* SDH : important : the dma transfer won't occur if the
         interrupt is enabled */
      call Usart.clrRxIntr();
      call Usart.disableRxIntr();
      call DmaChannel.setupTransfer(DMA_REPEATED_SINGLE_TRANSFER,
                                    DMA_TRIGGER_URXIFG1,
                                    DMA_EDGE_SENSITIVE,
                                    (void *)U1RXBUF_,
                                    (void *)buf,
                                    len,
                                    DMA_BYTE,
                                    DMA_BYTE,
                                    DMA_ADDRESS_UNCHANGED,
                                    DMA_ADDRESS_INCREMENTED);
      call DmaChannel.startTransfer();

      /* start the timeout */
      /* this will be fired when the buffer is about a third full so we
         can deliver the first half... */
      m_rx_last_check = 0;
      m_rx_last_delivery = 0;
      call RxAbort.startAt(call RxAbort.getNow(), 
                           m_byte_time * (m_rx_len / 12));
    }
    return SUCCESS;
  }
  async event void UsartInterrupts.rxDone[uint8_t id]( uint8_t data ) {
    /* if there were a buffer, we would have recieved it on the dma
       channel ... */
    if (!m_rx_buf) 
      signal UartStream.receivedByte[id]( data );
  }

  async event void RxAbort.fired() { 
    bool deliver = FALSE;
    uint16_t sz, last_delivery = 0;

    atomic {
      sz = m_rx_len - DMA2SZ;
      if (sz == m_rx_last_check) {
        /* always deliver if we didn't get any new bytes in this window */
        deliver = TRUE;
        last_delivery = m_rx_last_delivery;
        m_rx_last_delivery = sz;
        // call Leds.led1Toggle();

      }
      m_rx_last_check = sz;
    }

    if (deliver && sz - last_delivery > 0) {
      signal UartStream.receiveDone[current_owner](m_rx_buf + last_delivery, 
                                                   sz - last_delivery, SUCCESS);
    }

    call RxAbort.startAt(call RxAbort.getNow(), m_byte_time * (m_rx_len / 12));
  }
  
  async event void DmaChannel.transferDone(error_t success) {
    uint16_t last_delivery;
    atomic {
      last_delivery = m_rx_last_delivery;
      m_rx_last_delivery = 0;
    }
    signal UartStream.receiveDone[current_owner](m_rx_buf + last_delivery, 
                                                 m_rx_len - last_delivery, success);
  }

  async command error_t UartStream.send[ uint8_t id ]( uint8_t* buf, uint16_t len ) {
    if (call UsartResource.isOwner[id]() == FALSE)
      return FAIL;
    if ( len == 0 )
      return FAIL;
    else if ( m_tx_buf )
      return EBUSY;
    m_tx_buf = buf;
    m_tx_len = len;
    m_tx_pos = 0;
    current_owner = id;
    call Usart.tx( buf[ m_tx_pos++ ] );
    return SUCCESS;
  }
  
  async event void UsartInterrupts.txDone[uint8_t id]() {
    if(current_owner != id) {
      uint8_t* buf = m_tx_buf;
      m_tx_buf = NULL;
      signal UartStream.sendDone[id]( buf, m_tx_len, FAIL );
    }
    else if ( m_tx_pos < m_tx_len ) {
      call Usart.tx( m_tx_buf[ m_tx_pos++ ] );
    }
    else {
      uint8_t* buf = m_tx_buf;
      m_tx_buf = NULL;
      signal UartStream.sendDone[id]( buf, m_tx_len, SUCCESS );
    }
  }
  
  async command error_t UartByte.send[ uint8_t id ]( uint8_t data ) {
    if (call UsartResource.isOwner[id]() == FALSE)
      return FAIL;
    call Usart.clrTxIntr();
    call Usart.disableTxIntr ();
    call Usart.tx( data );
    while( !call Usart.isTxIntrPending() );
    call Usart.clrTxIntr();
    call Usart.enableTxIntr();
    return SUCCESS;
  }
  
  async command error_t UartByte.receive[ uint8_t id ]( uint8_t* byte, uint8_t timeout ) {
    
    uint16_t timeout_micro = m_byte_time * timeout + 1;
    uint16_t start;
    
    if (call UsartResource.isOwner[id]() == FALSE)
      return FAIL;
    start = call Counter.get();
    while( !call Usart.isRxIntrPending() ) {
      if ( ( call Counter.get() - start ) >= timeout_micro )
				return FAIL;
    }
    *byte = call Usart.rx();
    
    return SUCCESS;

  }
  
  async event void Counter.overflow() {}
  
  default async command error_t UsartResource.isOwner[ uint8_t id ]() { return FAIL; }
  default async command error_t UsartResource.request[ uint8_t id ]() { return FAIL; }
  default async command error_t UsartResource.immediateRequest[ uint8_t id ]() { return FAIL; }
  default async command error_t UsartResource.release[ uint8_t id ]() { return FAIL; }
  default async command msp430_uart_union_config_t* Msp430UartConfigure.getConfig[uint8_t id]() {
    return &msp430_uart_default_config;
  }

  default async event void UartStream.sendDone[ uint8_t id ](uint8_t* buf, uint16_t len, error_t error) {}
  default async event void UartStream.receivedByte[ uint8_t id ](uint8_t byte) {}
  default async event void UartStream.receiveDone[ uint8_t id ]( uint8_t* buf, uint16_t len, error_t error ) {}
  default event void Resource.granted[ uint8_t id ]() {}

}
