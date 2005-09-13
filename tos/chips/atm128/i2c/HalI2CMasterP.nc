/**
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
 *
 *  @author Martin Turon <mturon@xbow.com>
 *
 *  $Id: HalI2CMasterP.nc,v 1.1.2.1 2005-09-13 06:25:07 mturon Exp $
 */

#include "Atm128I2C.h"

/**
 * This driver implements an interupt driven I2C Master controller 
 * Hardware Abstraction Layer (HAL) to the ATmega128 
 * two-wire-interface (TWI) hardware subsystem.
 *
 * @version    2005/9/11    mturon     Initial version
 */
generic module HalI2CMasterP (uint8_t device)
{
    provides {
	interface HalI2CMaster as I2CDevice;
    }
    uses {
	interface HplI2CBus as I2C;
    }
}
implementation {
    enum {
	I2C_READY,
	I2C_PING,
	I2C_READ,
	I2C_WRITE,
    };

    uint8_t i2cMode;      //!< What type of transaction are we working on?
    uint8_t i2cOffset;    //!< Offset address into device memmap to read/write
     int8_t i2cLength;    //!< Length of data to read/write

    norace uint8_t *i2cData;     //!< Pointer to next data byte

    /**
     * An efficient I2C engine for the ATmega128.  This task handles state 
     * transitions triggered by the .symbolDone() interrupt of the hardware
     * I2C subsystem.  The hardware stores actual subtransaction state in 
     * the status register.  The type of user transaction (i2cMode) drives 
     * this engine at a higher level.  
     *
     * @author   Martin Turon
     *
     * @version  2005/9/10    mturon      Initial version
     */
    void task i2cEngine() {
	uint8_t state = call I2C.status();

	switch (i2cMode) {
	    case I2C_PING:
	    case I2C_READ:
		switch (state) {
		    case ATM128_I2C_START:
			call I2C.deviceRead(device);   // talk in read mode
			call I2C.send();
			break;
			
		    case ATM128_I2C_MR_SLA_ACK:
		    case ATM128_I2C_MR_DATA_ACK:
			if (i2cLength-- > 0) {
			    // if data left, read next byte
			    call I2C.send();
			} else {
			    // otherwise, complete with success
			    call I2C.end();
			    i2cMode = I2C_READY;
			    
			    if (i2cMode == I2C_PING) {	
				signal I2CDevice.pingDone(SUCCESS);
			    } else {
				signal I2CDevice.readDone();   
			    }
			}
			break;
			
		    default:
			call I2C.end();
			i2cMode = I2C_READY;
			// signal error
		}
		break;

	    case I2C_WRITE:
		switch (state) {
		    case ATM128_I2C_START:
			call I2C.deviceWrite(device);  // talk in write mode
			call I2C.send();
			break;

		    case ATM128_I2C_MW_SLA_ACK:
		    case ATM128_I2C_MW_DATA_ACK:
			if (i2cLength-- > 0) {
			    // if data left, write next byte
			    call I2C.set(*i2cData);
			    call I2C.send();
			} else {
			    // otherwise, clean exit
			    call I2C.end();
			    i2cMode = I2C_READY;			    
			    signal I2CDevice.writeDone();
			}
			break;

		    default:
			call I2C.end();
			i2cMode = I2C_READY;
			// signal error
		}
		break;
	}

	if (i2cMode == I2C_READY) return;

	// start timeout timer
    }

  /** Ping a I2C slave device to see if it exists. */
  command error_t I2CDevice.ping() {
      if (i2cMode != I2C_READY) 
	  return FAIL;

      i2cMode   = I2C_PING;
      i2cData   = NULL;
      i2cLength = 0;
      call I2C.begin();
      return SUCCESS;
  }

  /** Write a byte sequence to an I2C slave device. */
  command error_t I2CDevice.write(uint8_t *data, uint8_t length) {
      if (i2cMode != I2C_READY) 
	  return FAIL;

      i2cMode   = I2C_WRITE;
      i2cData   = data;
      i2cLength = length;
      call I2C.begin();
      return SUCCESS;
  }

  /** Read a byte sequence from an I2C slave device. */
  command error_t I2CDevice.read(uint8_t *data, uint8_t length) {
      if (i2cMode != I2C_READY) 
	  return FAIL;

      i2cMode   = I2C_READ;
      i2cData   = data;
      i2cLength = length;
      call I2C.begin();
      return SUCCESS;
  }

  default event void I2CDevice.pingDone  (error_t result) {}
  default event void I2CDevice.readDone  () {}
  default event void I2CDevice.writeDone () {}

  /** Intercept interrupt signal when pending symbol completes. */
  async event void I2C.symbolSent() { 
      if (call I2C.status() == ATM128_I2C_MW_DATA_ACK) {
	  // If reading, grab the next data byte.
	  if (i2cData != NULL) 
	      *i2cData++ = call I2C.get();
      }
      // Queue up handling for next symbol
      post i2cEngine();
  }
}
