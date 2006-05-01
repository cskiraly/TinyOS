/// $Id: Atm128I2CMasterP.nc,v 1.1.2.2 2006-05-01 21:50:50 scipio Exp $

/*
 *  Copyright (c) 2004-2005 Crossbow Technology, Inc.
 *  All rights reserved.
 *
 *  Permission to use, copy, modify, and distribute this software and its
 *  documentation for any purpose, without fee, and without written
 *  agreement is hereby granted, provided that the above copyright
 *  notice, the (updated) modification history and the author appear in
 *  all copies of this source code.
 *
 *  Permission is also granted to distribute this software under the
 *  standard BSD license as contained in the TinyOS distribution.
 *
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS `AS IS'
 *  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
 *  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 *  ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS 
 *  BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
 *  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, LOSS OF USE, DATA, 
 *  OR PROFITS) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
 *  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
 *  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF 
 *  THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "Atm128I2C.h"

/**
 * This driver implements an interupt driven I2C Master controller 
 * Hardware Abstraction Layer (HAL) to the ATmega128 
 * two-wire-interface (TWI) hardware subsystem.
 *
 * @author Martin Turon <mturon@xbow.com>
 * @author Philip Levis
 *
 * @version $Id: Atm128I2CMasterP.nc,v 1.1.2.2 2006-05-01 21:50:50 scipio Exp $
 */
generic module Atm128I2CMasterP() {
  provides interface AsyncStdControl;
  provides interface I2CPacket;
  
  uses interface HplAtm128I2CBus as I2C;
  uses interface Leds as ReadLeds;
  uses interface Leds as WriteLeds;
}
implementation {
  task void readDoneTask();
  task void writeDoneTask();

  enum {
    I2C_OFF     = 0,
    I2C_IDLE    = 1,
    I2C_READING = 2,
    I2C_WRITING = 3,
    I2C_SPINOUT = 10000,
  } atm128_i2c_state_t;

  uint8_t state = I2C_OFF;
  
  uint8_t packetAddr;
  uint8_t* packetPtr;
  uint8_t packetLen;

  async command error_t AsyncStdControl.start() {
    atomic {
      if (state == I2C_OFF) {
	call I2C.init(FALSE);
	call I2C.enable(TRUE);
	call I2C.enableAck(TRUE);
	state = I2C_IDLE;
	return SUCCESS;
      }
      else {
	return FAIL;
      }
    }
  }

  async command error_t AsyncStdControl.stop() {
    atomic {
      if (state == I2C_IDLE) {
	call I2C.enable(FALSE);
	call I2C.enableInterrupt(FALSE);
	call I2C.clearInterruptPending();
	call I2C.off();
	state = I2C_OFF;
	return SUCCESS;
      }
      else {
	return FAIL;
      }
    }
  }

  error_t i2c_abort() {
    call I2C.enableInterrupt(FALSE);
    call I2C.stop();
    call I2C.clearInterruptPending();
    return FAIL;
  }

  bool i2c_wait() {
    uint16_t i;
    for (i = 0; i < I2C_SPINOUT; i++) {
      if (call I2C.isInterruptPending()) {
	return TRUE;
      }
    }
    return FALSE;
  }
  
  async command error_t I2CPacket.read(uint8_t addr, uint8_t* data, uint8_t len) {
    uint8_t localLen;
    bool waitSuccess;
    atomic {
      if (state == I2C_IDLE) {
	state = I2C_READING;
      }
      else if (state == I2C_OFF) {
	return EOFF;
      }
      else {
	return EBUSY;
      }
    }
    /* This follows the procedure described on page 209 of the atmega128L
     * data sheet. It is synchronous (does not handle interrupts).*/
    atomic {
      packetAddr = addr;
      packetPtr = data;
      packetLen = len;
      localLen = len;
    }
    /* Clear interrupt pending, send the I2C start command and abort
       if we're not in the start state.*/
    call I2C.enableInterrupt(FALSE);
    call I2C.start();
    waitSuccess = i2c_wait();
    if (!waitSuccess || call I2C.status() != ATM128_I2C_START) {
      call ReadLeds.led1On();
      return i2c_abort();
    }
    
    /* Clear the start bit, write the address and abort if we're not in
       the right state. */
    call I2C.write(addr | ATM128_I2C_SLA_READ);
    /* We don't need to clear the interrupt pending bit because
       clearing the start bit will do so automatically (it reads TWINT
       to be 1, then writes that back). */
    call I2C.clearStart();
    waitSuccess = i2c_wait();
    if (!waitSuccess) {
      call ReadLeds.led1On();
      return i2c_abort();
    }
    else if (call I2C.status() != ATM128_I2C_MR_SLA_ACK) {
      call ReadLeds.led2On();
      return i2c_abort();
    }
    
    /* Read in the data bytes. */
    for (len = 0; len < localLen; len++) {
      call I2C.clearInterruptPending();
      data[len] = call I2C.read();
      waitSuccess = i2c_wait();
      if (!waitSuccess) {
	call ReadLeds.led2On();	
	return i2c_abort();
      }
      else if (call I2C.status() != ATM128_I2C_MR_DATA_ACK) {
	call ReadLeds.led2On();
	return i2c_abort();
      }
    }
    /* Send a stop condition and clear TWINT to send it. */
    call I2C.stop();
    post readDoneTask();
    return SUCCESS;
  }

  async command error_t I2CPacket.write(uint8_t addr, uint8_t* data, uint8_t len) {
    uint8_t localLen;
    bool waitSuccess;
    atomic {
      if (state == I2C_IDLE) {
	state = I2C_READING;
      }
      else if (state == I2C_OFF) {
	return EOFF;
      }
      else {
	return EBUSY;
      }
    }
    /* This follows the procedure described on page 209 of the atmega128L
     * data sheet. It is synchronous (does not handle interrupts).*/
    atomic {
      packetAddr = addr;
      packetPtr = data;
      packetLen = len;
      localLen = len;
    }
    /* Clear interrupt pending, send the I2C start command and abort
       if we're not in the start state.*/
    call I2C.enableInterrupt(FALSE);
    call I2C.start();
    waitSuccess = i2c_wait();
    if (!waitSuccess || call I2C.status() != ATM128_I2C_START) {
      call WriteLeds.led0On();
      return i2c_abort();
    }
    
    /* Clear the start bit, write the address and abort if we're not in
       the right state. */
    call I2C.write(addr | ATM128_I2C_SLA_WRITE);
    /* We don't need to clear the interrupt pending bit because
       clearing the start bit will do so automatically (it reads TWINT
       to be 1, then writes that back). */
    call I2C.clearStart();
    waitSuccess = i2c_wait();
    if (!waitSuccess || call I2C.status() != ATM128_I2C_MW_SLA_ACK) {
      call WriteLeds.led1On();
      return i2c_abort();
    }
    
    /* Read in the data bytes. */
    for (len = 0; len < localLen; len++) {
      call I2C.write(data[len]);
      call I2C.clearInterruptPending();
      waitSuccess = i2c_wait();
      if (!waitSuccess) {
	call WriteLeds.led1On();	
	return i2c_abort();
      }
      else if (call I2C.status() != ATM128_I2C_MW_DATA_ACK) {
	call WriteLeds.led2On();
	return i2c_abort();
      }
    }

    /* Send a stop condition and clear TWINT to send it. */
    call I2C.stop();
    post writeDoneTask();
    return SUCCESS;
  }
  
  task void readDoneTask() {
    uint8_t addr;
    uint8_t len;
    uint8_t* ptr;

    atomic {
      addr = packetAddr;
      len = packetLen;
      ptr = packetPtr;
      state = I2C_IDLE;
    }
    
    signal I2CPacket.readDone(addr, ptr, len, SUCCESS);
  }
  
  task void writeDoneTask() {
    uint8_t addr;
    uint8_t len;
    uint8_t* ptr;

    atomic {
      addr = packetAddr;
      len = packetLen;
      ptr = packetPtr;
      state = I2C_IDLE;
    }
    
    signal I2CPacket.writeDone(addr, ptr, len, SUCCESS);
  }

  async event void I2C.symbolSent() {}
}
