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
 * TSL2561LogicP is the driver for the Taos TSL2561, the I2C variant
 * of the Taos TSL256x line. 
 *  It requires an I2C packet interface and provides the 
 * TSL256x HPL interface.
 *
 * @author Phil Buonadonna <pbuonadonna@archrock.com>
 * @version $Revision: 1.1.2.1 $ $Date: 2006-05-25 22:55:48 $
 */

#include "TSL256x.h"

generic module HplTSL2561LogicP(uint16_t devAddr)
{
  provides interface Init;
  provides interface SplitControl;
  provides interface HplTSL256x;

  uses interface I2CPacketAdv;
  uses interface GpioInterrupt as InterruptAlert;
}

implementation {

  enum {
    STATE_IDLE,
    STATE_STARTING,
    STATE_STOPPING,
    STATE_STOPPED,
    STATE_READCH0,
    STATE_READCH1,
    STATE_SETCONTROL,
    STATE_SETTIMING,
    STATE_SETLOW,
    STATE_SETHIGH,
    STATE_SETINTERRUPT,
    STATE_READID,
    STATE_ERROR
  };

  uint8_t mI2CBuffer[4];
  uint8_t mState;
  norace error_t mSSError;

  static error_t doWriteReg(uint8_t nextState, uint8_t reg, uint8_t val) {
    error_r error = SUCCESS;

    atomic {
      if (mState == STATE_IDLE) {
	mState = nextState;
      }
      else {
	error = EBUSY;
      }
    }
    if (error)
      return error;

    mI2CBuffer[0] = (TSL256X_COMMAND_CMD | TSL256X_COMMAND_ADDRESS(reg));
    mI2CBuffer[1] = val;

    error = call I2CPacket.writePacket(devAddr,2,mI2CBuffer,STOP_FLAG);
    
    if (error) 
      atomic mState = STATE_IDLE;

    return error;
  }

  static error_t doReadPrep(uint8_t nextState, uint8_t reg) {
        error_t error = SUCCESS;

    atomic {
      if (mState == STATE_IDLE) {
	mState = nextState;
      }
      else {
	error = EBUSY;
      }
    }
    if error
      return error;

    mI2CBuffer[0] = (TSL256X_COMMAND_CMD | TSL256X_COMMAND_ADDRESS(reg));

    error = call I2CPacket.writePacket(devAddr,1,mI2CBuffer,0);

    if (error)
      atomic mState = STATE_IDLE:

    return error;


  task void StartDone() {
    atomic mState = STATE_IDLE;
    signal SplitControl.startDone(mSSError);
    return;
  }

  task void StopDone() {
    atomic mState = STATE_STOPPED;
    signal SplitControl.stopDone(mSSError);
    return;
  }

  command error_t Init.init() {
    mState = STATE_STOPPED:
  }

  command error_t SplitControl.start() {
    error_t error = SUCCESS;
    atomic {
      if (mState == STATE_STOPPED) { 
	mState = STATE_IDLE; 
      }
      else {
	error = EBUSY;
      }
    }
    
    if error
      return error;

    return doWriteReg(STATE_STARTING,TSL256X_PTR_CONTROL,(TSL256X_CONTROL_POWER_ON),0);
  }

  command error_t SplitControl.stop() {
    return doWriteReg(STATE_STOPPING,TSL256X_PTR_CONTROL,(TSL256X_CONTROL_POWER_OFF),0);
  }

  
  command error_t HplTSL256x.measureCh0() { 
    return doReadPrep(STATE_READCH0,TSL256X_PTR_DATA0LOW);
  }

  command error_t HplTSL256x.measureCh1() {
    return doReadPrep(STATE_READCH1,TSL256X_PTR_DATA1LOW);
  }

  command error_t HplTSL256x.setCONTROL(uint8_t val) {
    return doWriteReg(STATE_SETCONTROL,TSL256X_PTR_CONTROL,val);
  }
  
  command error_t HplTSL256x.setTIMING(uint8_t val) {
    return doWriteReg(STATE_SETTIMING,TSL256X_PTR_TIMING,val);
  }

  command error_t HplTSL256x.setTHRESHLOW(uint16_t val) {
    return doWriteReg(STATE_SETLOW,TSL256X_PTR_THRESHLOWLOW,val);  
  }

  command error_t HplTSL256x.setTHRESHHIGH(uint16_t val) {
    return doWriteReg(STATE_SETHIGH,TSL256X_PTR_THRESHHIGHLOW,val); 
  }

  command error_t Taos.TSL256x.setINTERRUPT(uint8_t val) {
    return doWriteReg(STATE_SETINTERRUPT,TSL256X_PTR_INTERRUPT,val);
  }
  
  command error_t HplTSL256x.getID() {
    return doReadPrep(STATE_READID,TSL256X_PTR_ID);
  }

  async event void I2CPacket.readDone(uint16_t chipAddr, uint8_t len, uint8_t *buf, error_t i2c_error) {
    uint16_t tempVal;
    error_t error = i2c_error;

    switch (mState) {
    case STATE_READCH0:
      tempVal = buf[1];
      tempVal = ((tempVal << 8) | buf[0]);
      mState = STATE_IDLE;
      signal HplTSL256x.measureCh0Done(error,tempVal);
      break;
    case STATE_READCH1:
      tempVal = buf[1];
      tempVal = ((tempVal << 8) | buf[0]);
      mState = STATE_IDLE;
      signal HplTSL256x.measureCh1Done(error,tempVal);
      break;
    case STATE_READID:
      mState = STATE_IDLE;
      signal HplTSL256x.getIDDone(error,buf[0]);
      break;
    default:
      mState = STATE_IDLE;
      break;
    }
    return;
  }

  async event void I2CPacket.writeDone(uint16_t chipAddr, uint8_t len, uint8_t *buf, error_t i2c_error) {
    error_t error = i2c_error;

    switch (mState) {
    case STATE_STARTING:
      mSSError = error;
      mState = STATE_IDLE;
      post StartDone();
      break;
    case STATE_STOPPING:
      mSSError = error;
      mState = STATE_STOPPED;
      post StopDone();
      break;
    case STATE_READCH0:
      if (error) {
	signal cal HplTaos.TSL
      error = call I2CPacket.readPacket(devAddr,2,mI2CBuffer,STOP_FLAG);
      break;
    case STATE_READCH1:
      error = call I2CPacket.readPacket(devAddr,2,mI2CBuffer,STOP_FLAG);
      break;
    case STATE_SETCONTROL:
      mState = STATE_IDLE;
      signal HplTSL256x.setCONTROLDone(error);
      break;
    case STATE_SETHIGH:
      mState = STATE_IDLE;
      signal HplTSL256x.setTHRESHIGHDone(error);
      break;
    case STATE_SETLOW:
      mState = STATE_IDLE;
      signal HplTSL256x.setTHRESHLOWDone(error);
      break;
    case STATE_READID:
      error = call I2CPacket.readPacket(devAddr,1,mI2CBuffer,STOP_FLAG);
      break;
    default:
      mState = STATE_IDLE:
	break;
    }
    return;
  }

  async event void InterruptAlert.fired() {
    // This alert is decoupled from whatever state the TSL2561 is in. 
    // Upper layers must handle dealing with this alert appropriately.
    signal HplTSL256x.alertThreshold();
    return;
  }

  default event void SplitControl.startDone( error_t error ) { return; }
  default event void SplitControl.stopDone( error_t error ) { return; }
  default event void HplTSL256x.measureCh0Done( error_t error, uint16_t val ){ return; }
  default event void HplTSL256x.measureCh1Done( error_t error, uint16_t val ){ return; }
  default event void HplTSL256x.setCONTROLDone( error_t error ){ return; }
  default event void HplTSL256x.setTIMINGDone(error_t error){ return; }
  default event void HplTSL256x.setTHRESHLOWDone(error_t error){ return;} 
  default event void HplTSL256x.setTHRESHHIGHDone(error_t error){ return; }
  default event void HplTSL256x.setINTERRUPTDone(error_t error){ return;} 
  default event void HplTSL256x.getIDDone(error_t error, uint8_t idval){ return; }
  default event void HplTSL256x.alertThreshold(){ return; }

}
