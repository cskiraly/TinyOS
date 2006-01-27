/// $Id: HplAtm128I2CBusP.nc,v 1.1.2.1 2006-01-27 22:19:36 mturon Exp $

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

#define I2C_TIMEOUT 30000
#define F_CPU       7372800

#include "Atm128I2C.h"

/**
 * This driver implements direct I2C register access and a blocking master
 * controller for the ATmega128 via a Hardware Platform Layer (HPL) to its  
 * two-wire-interface (TWI) hardware subsystem.
 *
 * @author Martin Turon <mturon@xbow.com>
 *
 * @version    2005/9/11    mturon     Initial version
 */
module HplI2CBusP
{
    provides interface HplI2CBus as I2C;

    uses {
        interface Leds;
	interface BusyWait<TMicro,uint16_t> as uWait;
	interface GeneralIO as I2CClk;
	interface GeneralIO as I2CData;
    }
}
implementation {

  command void I2C.init() {
      // Set the internal pullup resisters
      call I2CClk.makeOutput();
      call I2CData.makeOutput();
      call I2CClk.set();
      call I2CData.set();
      
      TWSR = 0;                             // set prescaler == 0
      TWBR = (F_CPU / 100000UL - 16) / 2;   // set I2C baud rate
      // TWBR = 50;
  }

  /** Send START symbol and begin I2C bus transaction. */
  command void I2C.begin() {
      //TWCR = 1<<TWIE | 1<<TWEN | 1<<TWSTA | 1<<TWINT ;
      Atm128I2CControl_t ctrl;
      ctrl.bits = (Atm128I2CControl_s) { twen : 1, twint : 1, twsta : 1, twie : 1 };
      call I2C.setControl(ctrl);      
  }

  /** Signal STOP and end I2C bus transaction. */
  command void I2C.end() {
      Atm128I2CControl_t ctrl;
      ctrl.bits = (Atm128I2CControl_s) { twen : 1, twint : 1, twsto : 1, twie: 0 };
      call I2C.setControl(ctrl);      
  }

  /** Send next byte of I2C bus transaction. */
  command void I2C.send() {
      Atm128I2CControl_t ctrl;
      ctrl.bits = (Atm128I2CControl_s) { twen : 1, twint : 1, twie : 1 };
      call I2C.setControl(ctrl);      
  }

  error_t i2c_quit() {
      call I2C.end();
      return FAIL;
  }

  /** Ping a I2C slave device to see if it exists. */
  command error_t I2C.ping(uint8_t addr) {

//      call Leds.set(call I2C.isDone());

//      avr_i2c_enable();
//      avr_i2c_start();
//      avr_i2c_wait();

      call I2C.begin();
      call I2C.waitDone();

      call Leds.set(call I2C.status()>>3 & 0x7); 
      //(call I2C.getStatus()).bits.tws);

      // confirm start sent status
      if (!(call I2C.status() == ATM128_I2C_START)) return i2c_quit();


      call I2C.deviceRead(addr);
      call I2C.send();
      call I2C.waitDone();
      // confirm slave ack status
      if (!(call I2C.status() == ATM128_I2C_MR_SLA_ACK)) return i2c_quit();
      
      call I2C.end();

      return SUCCESS;
  }

  /** Write a byte to an I2C slave device. */
  command error_t I2C.write(uint8_t addr, uint8_t data) {
      call I2C.begin();
      call I2C.waitDone();
      // confirm start sent status
      if (!(call I2C.status() == ATM128_I2C_START)) return i2c_quit();

      call I2C.deviceWrite(addr);
      call I2C.send();
      call I2C.waitDone();
      // confirm slave ack status
      if (!(call I2C.status() == ATM128_I2C_MW_SLA_ACK)) return i2c_quit();
      
      call I2C.set(data);
      call I2C.send();
      call I2C.waitDone();
      // confirm data ack status
      if (!(call I2C.status() == ATM128_I2C_MW_DATA_ACK)) return i2c_quit();

      call I2C.end();

      return SUCCESS;
  }

  /** Read a byte from an I2C slave device. */
  command error_t I2C.read(uint8_t addr, uint8_t *data) {
      call I2C.begin();
      call I2C.waitDone();
      // confirm start sent status
      if (!(call I2C.status() == ATM128_I2C_START)) return i2c_quit();

      call I2C.deviceRead(addr);
      call I2C.send();
      call I2C.waitDone();
      // confirm slave ack status
      if (!(call I2C.status() == ATM128_I2C_MR_SLA_ACK)) return i2c_quit();
      
      call I2C.send();
      call I2C.waitDone();
      *data = call I2C.get();
      // confirm data ack status
      if (!(call I2C.status() == ATM128_I2C_MR_DATA_ACK)) return i2c_quit();

      call I2C.end();

      return SUCCESS;
  }

  /** Write one data byte to a given offset on a I2C slave device. */
  command error_t I2C.writeBuffer(uint8_t device, uint8_t *data, int8_t len) {
      call I2C.begin();
      call I2C.waitDone();
      // confirm start sent status
      if (!(call I2C.status() == ATM128_I2C_START)) return i2c_quit();

      call I2C.deviceWrite(device);
      call I2C.send();
      call I2C.waitDone();
      // confirm slave ack status
      if (!(call I2C.status() == ATM128_I2C_MW_SLA_ACK)) return i2c_quit();
      
      while (len-- > 0) {
	  call I2C.set(*data++);
	  call I2C.send();
	  call I2C.waitDone();
	  // confirm data ack status
	  if (!(call I2C.status() == ATM128_I2C_MW_DATA_ACK)) return i2c_quit();
      }

      call I2C.end();

      return SUCCESS;
  }

  /** Read one data byte to a given offset on a I2C slave device. */
  command error_t I2C.readBuffer(uint8_t device, uint8_t *data, int8_t len) {
      call I2C.begin();
      call I2C.waitDone();
      // confirm start sent status
      if (!(call I2C.status() == ATM128_I2C_START)) return i2c_quit();

      call I2C.deviceRead(device);
      call I2C.send();
      call I2C.waitDone();
      // confirm slave ack status
      if (!(call I2C.status() == ATM128_I2C_MR_SLA_ACK)) return i2c_quit();
            
      while (len-- > 0) {
	  call I2C.send();
	  call I2C.waitDone();
	  *data++ = call I2C.get();
	  // confirm data ack status
	  if (!(call I2C.status() == ATM128_I2C_MR_DATA_ACK)) return i2c_quit();
      }

      call I2C.end();

      return SUCCESS;
  }

  //=== Read the data registers. ========================================
  async command uint8_t I2C.get()    { return TWDR; }

  //=== Write the data registers. =======================================
  async command void I2C.set(uint8_t data)  { TWDR = data; }

  async command void I2C.deviceRead  (uint8_t addr)  { TWDR = addr | 0x01; }
  async command void I2C.deviceWrite (uint8_t addr)  { TWDR = addr; }

  //=== Read the control registers. =====================================
  async command Atm128I2CControl_t I2C.getControl() { 
    return *(Atm128I2CControl_t*)&TWCR; 
  }
  async command Atm128I2CStatus_t I2C.getStatus() { 
    return *(Atm128I2CStatus_t*)&TWSR; 
  }

  //=== Write the control registers. ====================================
  async command void I2C.setControl( Atm128I2CControl_t x ) {TWCR = x.flat;}
  async command void I2C.setStatus ( Atm128I2CStatus_t x )  {TWSR = x.flat;}

  async command uint8_t I2C.status() { return TWSR & 0xF8; }

  //=== Utility routines ===============================================

  async command bool I2C.isDone() { 
    return (call I2C.getControl()).bits.twint; 
  }

  async command error_t I2C.waitDone() { 
      int i = 0;
      while (!call I2C.isDone()) {
	  call uWait.wait(100);
	  if (i++ > I2C_TIMEOUT) return FAIL; // timeout
      }
      return SUCCESS;
  }

//  async command void I2C.enable()  { SET_BIT(TWCR,TWE);   }
//  async command void I2C.disable() { CLR_BIT(TWCR,TWE);   }

  default async event void I2C.symbolSent() { }
  AVR_NONATOMIC_HANDLER(SIG_2WIRE_SERIAL) {
      atomic signal I2C.symbolSent();
  }
}
