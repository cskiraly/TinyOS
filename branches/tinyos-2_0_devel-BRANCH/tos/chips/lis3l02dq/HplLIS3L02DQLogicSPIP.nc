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
 * This module is the driver components for the ST LIS3L02DQ 3-axis 
 * accelerometer in the 4 wire SPI mode. It requires the SPI packet
 * interface and provides the HplLIS3L02DQ HPL interface.
 *
 * @author Phil Buonadonna <pbuonadonna@archrock.com>
 * @version $Revision: 1.1.2.1 $ $Date: 2006-05-25 22:56:59 $
 */

generic module HplLIS3L02DQLogicP()
{
  provides interface Init;
  provides interface SplitControl;
  provides interface HplLIS3L02DQ;

  uses interface SpiPacket;
  uses interface GpioInterrupt as InterruptAlert;
}

implementation {

  enum {
    STATE_IDLE,
    STATE_STARTING,
    STATE_STOPPING,
    STATE_STOPPED,
    STATE_GETREG,
    STATE_SETREG,
    STATE_ERROR
  };

  uint8_t mSPIRxBuf[4],mSPITxBuf[4];
  uint8_t mState;
  bool misInited = FALSE;
  norace error_t mSSError;


  task void StartDone() {
    atomic mState = STATE_IDLE;
    signal SplitControl.startDone(SUCCESS);
    return;
  }

  task void StopDone() {
    atomic mState = STATE_STOPPED;
    signal SplitControl.stopDone(mSSError);
    return;
  }

  command error_t Init.init() {
    atomic {
      if (!misInited) {
	misInited = TRUE;
	mState = STATE_STOPPED:
      }
    }
  }

  command error_t SplitControl.start() {
    error_t error = SUCCESS;
    atomic {
      if (mState == STATE_STOPPED) { 
	mState = STATE_STARTING;
      }
      else {
	error = EBUSY;
      }
    }
    if (error) 
      return error;

    return post StartDone();
  }

  command error_t SplitControl.stop() {
    error_t error = SUCCESS;

    atomic {
      if (mState == STATE_IDLE) {
	mState = STATE_STOPPING;
      }
      else { 
	error = EBUSY;
      }
    }
    if (error)
      return error;

    return post StopDone();
  }
  
  command error_t HplLIS3L02DQ.getReg(uint8_t regAddr) {
    error_t error = SUCCESS;

    if((regAddr < 0x16) || (regAddr > 0x2A)) {
      error = EINVAL;
      return error;
    }
    mSPITxBuf[0] = regAddr | (1 << 7); // Set the READ bit
    mSPIRxBuf[1] = 0;
    error = call SPIPacket.send(mSPITxBuf,mSPIRxBuf,2);

    return error;

  }
  
  command error_t HplLIS3L02DQ.setReg(uint8_t regAddr, uint8_t val) {
    error_t error = SUCCESS;

    if((regAddr < 0x16) || (regAddr > 0x2A)) {
      error = EINVAL;
      return error;
    }
    mSPITxBuf[0] = regAddr;
    mSPIRxBuf[1] = val;
    error = call SPIPacket.send(mSPITxBuf,mSPIRxBuf,2);

    return error;
  }

  async event void SPIPacket.sendDone(uint8_t* txBuf, uint8_t* rxBuf, uint16_t len, error_t spi_error ) {
    error_t error = spi_error;

    switch (mState) {
    case STATE_GETREG:
      mState = STATE_IDLE;
      signal HplLIS3L02DQ.getReg(error, (txBuf[0] & 0x7F) , rxBuf[1]);
      break;
    case STATE_SETREG:
      mState = STATE_IDLE;
      signal HplLIS3L02DQ.getReg(error, (txBuf[0] & 0x7F), txBuf[1]);
      break;
    default:
      mState = STATE_IDLE;
      break;
    }
    return;
  }

  async event void InterruptAlert.fired() {
    // This alert is decoupled from whatever state the MAX136x is in. 
    // Upper layers must handle dealing with this alert appropriately.
    signal HplLIS3L02DQ.alertThreshold();
    return;
  }

  default event void SplitControl.startDone( error_t error ) { return; }
  default event void SplitControl.stopDone( error_t error ) { return; }

  default event void HplLIS3L02DQ.alertThreshold(){ return; }

}
