/// $Id: HplAtm128I2CBus.nc,v 1.1.2.1 2006-01-27 22:19:36 mturon Exp $

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
 * This driver implements direct I2C register access and a blocking master
 * controller for the ATmega128 via a Hardware Platform Layer (HPL) to its  
 * two-wire-interface (TWI) hardware subsystem.
 *
 * @author Martin Turon <mturon@xbow.com>
 *
 * @version    2005/9/11    mturon     Initial version
 */
interface HplI2CBus {

    command void init();    //!< Initialize i2c clock speed

    // Transaction interface
    command void begin();   //!< Start bus transaction (send start symbol)
    command void end();     //!< End bus transaction
    command void send();    //!< Send next byte of transaction

    // Data interface
    command error_t ping (uint8_t dev);              //!< Ping device
    command error_t write(uint8_t dev, uint8_t data);  //!< Write to device
    command error_t read (uint8_t dev, uint8_t *data); //!< Read from device

    command error_t writeBuffer(uint8_t dev, uint8_t *data, int8_t len);
    command error_t readBuffer (uint8_t dev, uint8_t *data, int8_t len);

    async command uint8_t get();               //!< Get data register
    async command void    set(uint8_t data);   //!< Set data register

    async command void deviceRead (uint8_t addr); //!< Set device to read
    async command void deviceWrite(uint8_t addr); //!< Set device to write

    async command Atm128I2CControl_t getControl();
    async command Atm128I2CStatus_t  getStatus();

    async command void setControl( Atm128I2CControl_t x );
    async command void setStatus ( Atm128I2CStatus_t x );
    
    async command uint8_t status();
    async command bool    isDone();
    async command error_t waitDone();

//    async command void enable(); 
//    async command void disable();

    async event void symbolSent();
}
