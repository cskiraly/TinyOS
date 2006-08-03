/*
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
 * @author Jonathan Hui <jhui@archrock.com>
 * @version $Revision: 1.1.2.2 $ $Date: 2006-08-03 18:10:41 $
 */

#include <I2C.h>

module Msp430I2CP {
  
  provides interface Resource[ uint8_t id ];
	provides interface ResourceConfigure[ uint8_t id ];
  provides interface I2CPacket<TI2CBasicAddr> as I2CBasicAddr;
  
  uses interface Resource as UsartResource[ uint8_t id ];
	uses interface Msp430I2CConfigure[ uint8_t id ];
  uses interface HplMsp430Usart as Usart;
  uses interface HplMsp430I2CInterrupts as I2CInterrupts;
  uses interface Leds;
  
}

implementation {
  
  enum {
    TIMEOUT = 64,
  };
  
  MSP430REG_NORACE(I2CTCTL);
  MSP430REG_NORACE(I2CIE);
  MSP430REG_NORACE(I2CIFG);
  MSP430REG_NORACE(I2CDR);
  MSP430REG_NORACE(I2CSA);
  MSP430REG_NORACE(U0CTL);
  
  norace uint8_t* m_buf;
  norace uint8_t m_len;
  norace uint8_t m_pos;
  norace i2c_flags_t m_flags;
  
  void nextRead();
  void nextWrite();
  void signalDone( error_t error );
  
  async command error_t Resource.immediateRequest[ uint8_t id ]() {
    error_t error = call UsartResource.immediateRequest[ id ]();
    if ( error == SUCCESS )
      call Usart.setModeI2C();
    return error;
  }
  
  async command error_t Resource.request[ uint8_t id ]() {
    return call UsartResource.request[ id ]();
  }

  async command uint8_t Resource.isOwner[ uint8_t id ]() {
    return call UsartResource.isOwner[ id ]();
  }
  
  async command void Resource.release[ uint8_t id ]() {
    call UsartResource.release[ id ]();
  }
  
	async command void ResourceConfigure.configure[ uint8_t id ]() {
		call Usart.setModeI2C(call Msp430I2CConfigure.getConfig[id]());
	}

	async command void ResourceConfigure.unconfigure[ uint8_t id ]() {
	}
	
  event void UsartResource.granted[ uint8_t id ]() {
    call Usart.setModeI2C();
    signal Resource.granted[ id ]();
  }
  
  default async command error_t UsartResource.request[ uint8_t id ]() { return FAIL; }
  default async command error_t UsartResource.immediateRequest[ uint8_t id ]() { return FAIL; }
	default async command void UsartResource.release[ uint8_t id ]() {}
  default event void Resource.granted[ uint8_t id ]() {}
	default async command msp430_i2c_config_t* Msp430SpiConfigure.getConfig[uint8_t id]() {
		return &msp430_i2c_default_config;
	}
  
  async command error_t I2CBasicAddr.read( i2c_flags_t flags,
					   uint16_t addr, uint8_t len, 
					   uint8_t* buf ) {
    
    m_buf = buf;
    m_len = len;
    m_flags = flags;
    m_pos = 0;
    
    U0CTL |= MST;
    I2CTCTL &= ~I2CTRX;
    
    I2CSA = addr;
    I2CIE = RXRDYIE | ARDYIE | NACKIE;
    if ( flags & I2C_START )
      I2CTCTL |= I2CSTT;
    else
      nextRead();
    
    return SUCCESS;
    
  }
  
  async command error_t I2CBasicAddr.write( i2c_flags_t flags,
					    uint16_t addr, uint8_t len,
					    uint8_t* buf ) {
    
    m_buf = buf;
    m_len = len;
    m_flags = flags;
    m_pos = 0;
    
    U0CTL |= MST;
    I2CTCTL |= I2CTRX;
    
    I2CSA = addr;
    I2CIE = TXRDYIE | ARDYIE | NACKIE;
    if ( flags & I2C_START )
      I2CTCTL |= I2CSTT;
    else
      nextWrite();
    
    return SUCCESS;
    
  }
  
  async event void I2CInterrupts.fired() {
    
    int i = 0;
    
    switch( I2CIV ) {
      
    case 0x04:
      if ( I2CDCTL & I2CBB )
	I2CTCTL |= I2CSTP;
      while( I2CDCTL & I2CBUSY );
      signalDone( FAIL );
      break;
      
    case 0x08:
      while( (I2CDCTL & I2CBUSY) ) {
	if ( i++ >= TIMEOUT ) {
	  signalDone( FAIL );
	  return;
	}
      }
      signalDone( SUCCESS );
      break;
      
    case 0x0A:
      nextRead();
      break;
      
    case 0x0C:
      nextWrite();
      break;
      
    default:
      break;

    }
    
  }
  
  void nextRead() {
    m_buf[ m_pos++ ] = I2CDR;
    if ( m_pos == m_len ) {
      if ( m_flags & I2C_STOP )
	I2CTCTL |= I2CSTP;
      else
	signalDone( SUCCESS );
    }
  }
  
  void nextWrite() {
    if ( ( m_pos == m_len - 1 ) && ( m_flags & I2C_STOP ) ) {
      I2CTCTL |= I2CSTP;
    }
    else if ( m_pos == m_len ) {
      signalDone( SUCCESS );
      return;
    }
    I2CDR = m_buf[ m_pos++ ];
  }
  
  void signalDone( error_t error ) {
    I2CIE = 0;
    if ( I2CTCTL & I2CTRX )
      signal I2CBasicAddr.writeDone( error, I2CSA, m_len, m_buf );
    else
      signal I2CBasicAddr.readDone( error, I2CSA, m_len, m_buf );
  }
  
}
