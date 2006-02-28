/* $Id: HalPXA27xI2CMasterM.nc,v 1.1.2.2 2006-02-28 03:07:35 philipb Exp $ */
/*
 * Copyright (c) 2005 Arched Rock Corporation 
 * All rights reserved. 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *	Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 *	Redistributions in binary form must reproduce the above copyright
 * notice, this list of conditions and the following disclaimer in the
 * documentation and/or other materials provided with the distribution.
 *  
 *   Neither the name of the Arched Rock Corporation nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE ARCHED
 * ROCK OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS
 * OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
 * TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
 * DAMAGE.
 */
/**
 * This Hal module implements the TinyOS 2.0 I2CPacket interface over
 * the PXA27x I2C Hpl
 *
 * @author Phil Buonadonna
 */

#include <I2CFlags.h>

module HalPXA27xI2CMasterM
{
  provides interface Init;
  provides interface I2CPacketAdv[uint8_t client];

  //uses interface Resource as I2CResource;
  uses interface HplPXA27xI2C as I2C;

}

implementation
{

  enum {
    I2C_STATE_IDLE,
    I2C_STATE_READSTART,
    I2C_STATE_READDATA,
    I2C_STATE_WRITESTART,
    I2C_STATE_WRITEDATA,
    I2C_STATE_WRITESTOP,
    I2C_STATE_ERROR
  };

  uint8_t mI2CState;
  uint16_t curDevAddr;
  uint8_t *curBuf, curBufLen, curBufIndex;

  command error_t Init.init() {

    uint8_t mI2CState = I2C_STATE_IDLE;
    
  }

  async command error_t I2CPacketAdv.readPacket(uint16_t addr, uint8_t length, uint8_t* data, i2c_flags_t flags) {
    error_t error = SUCCESS;
    uint8_t tmpAddr;

    atomic {
      if (mI2CState == I2C_STATE_IDLE) {
	mI2CState = I2C_STATE_READSTART;
	curDevAddr = addr;
	curBuf = data;
	curBufLen = length;
	curBufIndex = 0;
      }
      else {
	error = EBUSY;
      }
    }

    if (error) {
      return error;
    }

    tmpAddr = (((addr << 1) & 0xFF) | 0x1);

    call I2C.setIDBR(tmpAddr);

    call I2C.setICR((call I2C.getICR() & ~ICR_ALDIE) | ICR_BEIE | ICR_ITEIE | ICR_SCLEA | ICR_TB | ICR_START);
    
    return error;
  }

  async command error_t I2CPacketAdv.writePacket(uint16_t addr, uint8_t length, uint8_t* data, i2c_flags_t flags) {

  }

  async event void I2C.interruptI2C() {
    uint32_t valISR;

    valISR = call I2C.getISR();

    switch (mI2CState) {
    case I2C_STATE_IDLE:
      // Should never get here. Reset all pending interrupts.
      call I2C.setISR(valISR);
      break;
    case I2C_STATE_READSTART:
      call I2C.setISR(ISR_ITE);
      call I2C.setICR((call I2C.getICR()) & ~(ICR_ITEIE | ICR_ACKNAK | ICR_STOP | ICR_START));
      call I2C.setICR((call I2C.getICR()) | (ICR_ALDIE | ICR_DRFIE | ICR_TB)); 
      mI2CState = I2C_STATE_READ;

      break;
    case I2C_STATE_READ:
      call I2C.setISR(ISR_IRF);
      curBuf[curBufIndex] = call I2C.getIDBR();
      curBufIndex++;
      call I2C.setICR((call I2C.getICR()) | ICR_TB);
      
      break;
    case I2C_STATE_WRITESTART:
      break;
    case I2C_STATE_WRITEDATA:
      break;
    case I2C_STATE_WRITESTOP:
      break;
    default:
      break;
    }

      
    return;
  }

  default async event void I2CPacketAdv.readPacketDone(uint16_t addr, uint8_t length, 
						    uint8_t* data, error_t error) {
    return;
  }

  default async event void I2CPacketAdv.writePacketDone(uint16_t addr, uint8_t length, 
						     uint8_t* data, error_t error) { 
    return;
  }
}
