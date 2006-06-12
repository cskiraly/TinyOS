/* $Id: HalPXA27xI2CMasterP.nc,v 1.1.2.1 2006-03-01 03:28:42 philipb Exp $ */
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

module HalPXA27xI2CMasterP
{
  provides interface Init;
  provides interface I2CPacketAdv;

  uses interface HplPXA27xI2C as I2C;
}

implementation
{
  enum {
    I2C_STATE_IDLE,
    I2C_STATE_READSTART,
    I2C_STATE_READDATA,
    I2C_STATE_READEND,
    I2C_STATE_WRITE,
    I2C_STATE_WRITEEND,
    I2C_STATE_ERROR
  };

  uint8_t mI2CState;
  uint16_t mCurTargetAddr;
  uint8_t *mCurBuf, mCurBufLen, mCurBufIndex;
  i2c_flags_t mCurFlags;
  const uint32_t mBaseICRFlags = (ICR_FM | ICR_BEIE | ICR_IUE | ICR_SCLE);
  
  static error_t startI2CTransact(uint8_t nextState, uint16_t addr, uint8_t length, uint8_t *data, 
			   i2c_flags_t flags, bool bRnW) {
    error_t error = SUCCESS;
    uint8_t tmpAddr;

    if ((data == NULL) || (length == 0)) {
      return EINVAL;
    }

    atomic {
      if (mI2CState == I2C_STATE_IDLE) {
	mI2CState = nextState;
	mCurTargetAddr = addr;
	mCurBuf = data;
	mCurBufLen = length;
	mCurBufIndex = 0;
	mCurFlags = flags;
      }
      else {
	error = EBUSY;
      }
    }
    if (error) {
      return error;
    }

    if (call I2C.getISR() | ISR_UB) {
      return EBUSY;
    }

    tmpAddr = (rRnW) ? 0x1 : 0x0;
    tmpAddr |= ((addr << 1) & 0xFE);

    call I2C.setIDBR(tmpAddr);
    call I2C.setICR( mBaseICRFlags | ICR_ITEIE | ICR_TB | ICR_START);
    
    return error;
  }

  task void handleReadError() {
    call I2C.setISR(0x7F0);
    call I2C.setICR(mBaseICRFlags | ICR_MA);
    call I2C.setICR(ICR_UR);
    call I2C.setICR(mBaseICRFlags);
    mI2CState = I2C_STATE_IDLE;
    atomic {
      signal I2CPacketAdv.readPacketDone(mCurTargetAddr,mCurBufLen,mCurBuf,FAIL);
    }
    return;
  }
    
  task void handleWriteError() {
    call I2C.setISR(0x7F0);
    call I2C.setICR(mBaseICRFlags | ICR_MA);
    call I2C.setICR(ICR_UR);
    call I2C.setICR(mBaseICRFlags);
    mI2CState = I2C_STATE_IDLE;
    atomic {
      signal I2CPacketAdv.readPacketDone(mCurTargetAddr,mCurBufLen,mCurBuf,FAIL);
    }
    return;
  }

  command error_t Init.init() {
    atomic {
      mI2CState = I2C_STATE_IDLE;
    }    
  }

  async command error_t I2CPacketAdv.readPacket(uint16_t addr, uint8_t length, uint8_t* data, i2c_flags_t flags) {
    error_t error = SUCCESS;
    uint8_t tmpAddr;

    error = startI2CTransact(I2C_STATE_READSTART,addr,length,data,flags,TRUE);
    return error;
  }

  async command error_t I2CPacketAdv.writePacket(uint16_t addr, uint8_t length, uint8_t* data, i2c_flags_t flags) {
    error_t error = SUCCESS;
    uint8_t tmpAddr;

    error = startI2CTransact(I2C_STATE_WRTESTART,addr,length,data,flags,FALSE);
    return error;
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
      call I2C.setISR(ISR_ITE | ISR_ALD);
      if (call I2C.getISR() & ISR_BED) {
	mI2CState = I2C_STATE_ERROR;
	post handleReadError();
	break;
      }
      call I2C.setICR((mBaseICRFlags) | (ICR_ALDIE | ICR_DRFIE | ICR_TB)); 
      mI2CState = I2C_STATE_READ;
      break;

    case I2C_STATE_READ:
      call I2C.setISR(ISR_IRF);
      if (call I2C.getISR() & (ISR_BED | ISR_ALD)) {
	mI2CState = I2C_STATE_ERROR;
	post handleReadError();
	break;
      }
      mCurBuf[mCurBufIndex] = call I2C.getIDBR();
      mCurBufIndex++;
      if (mCurBufIndex >= (mCurBufLen - 1)) {
	call I2C.setICR((mBaseICRFlags) | (ICR_ALDIE | ICR_DRFIE | ICR_ACKNAK | ICR_TB | ICR_STOP));
	mI2CState = I2C_STATE_READEND;
      }
      else {
	call I2C.setICR((mBaseICRFlags) | (ICR_ALDIE | ICR_DRFIE | ICR_TB));
      }
      break;

    case I2C_STATE_READEND:
      call I2C.setISR(ISR_IRF);
      if (call I2C.getISR() & (ISR_BED | ISR_ALD)) {
	mI2CState = I2C_STATE_ERROR;
	post handleReadError();
	break;
      }
      mCurBuf[mCurBufIndex] = call I2C.getIDBR();
      mI2CState = I2C_STATE_IDLE;
      signal I2CPacketAdv.readPacketDone(mCurTargetAddr,mCurBufLen,mCurBuf,SUCCESS);
      break;

    case I2C_STATE_WRITESTART:
      call I2C.setISR(ISR_ALD);
      // Fall through...
    case I2C_STATE_WRITE:
      call I2C.setISR(ISR_ITE);
      if (call I2C.getISR() & (ISR_BED | ISR_ALD)) {
	mI2CState = I2C_STATE_ERROR;
	post handleWriteError();
	break;
      }
      call I2C.setIDBR(mCurBuf[mCurBufIndex]);
      mCurBufIndex++;
      if (mCurBufIndex >= mCurBufLen) {
	call I2C.setICR((mBaseICRFlags) | (ICR_ALDIE | ICR_TB | ICR_STOP));
	mI2CState = I2C_STATE_WRITEEND;
      }
      else {
	call I2C.setICR((mBaseICRfFlags) | (ICR_ALDIE | ICR_TB | ICR_STOP));
	mI2CState = I2C_STATE_WRITE;
      }
      break;

    case I2C_STATE_WRITEEND:
      call I2C.setISR(ISR_ITE);
      if (call I2C.getISR() & (ISR_BED | ISR_ALD)) {
	mI2CState = I2C_STATE_ERROR;
	post handleWriteError();
	break;
      }
      mI2CState= I2C_STATE_IDLE;
      signal I2CPacketAdv.writePacketDone(mCurTargetAddr,mCurBufLen,mCurBuf,SUCCESS);
      break;

    default:
      // Clear all pending interupts
      call I2C.setISR(valISR);
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
