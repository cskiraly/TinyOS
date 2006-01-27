/// $Id: Atm128I2C.h,v 1.1.2.2 2006-01-27 22:19:34 mturon Exp $

/*
 * Copyright (c) 2004-2005 Crossbow Technology, Inc.  All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL CROSSBOW TECHNOLOGY OR ANY OF ITS LICENSORS BE LIABLE TO 
 * ANY PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL 
 * DAMAGES ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN
 * IF CROSSBOW OR ITS LICENSOR HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH 
 * DAMAGE. 
 *
 * CROSSBOW TECHNOLOGY AND ITS LICENSORS SPECIFICALLY DISCLAIM ALL WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY 
 * AND FITNESS FOR A PARTICULAR PURPOSE. THE SOFTWARE PROVIDED HEREUNDER IS 
 * ON AN "AS IS" BASIS, AND NEITHER CROSSBOW NOR ANY LICENSOR HAS ANY 
 * OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR 
 * MODIFICATIONS.
 */

/// @author Martin Turon <mturon@xbow.com>

#ifndef _H_Atm128I2C_h
#define _H_Atm128I2C_h

#define ATM128_I2C_SLA_W 0x00
#define ATM128_I2C_SLA_R 0x01

typedef uint8_t Atm128_TWBR_t;  //!< Two Wire Bit Rate Register
typedef uint8_t Atm128_TWDR_t;  //!< Two Wire Data Register

/** I2C Control Register -- TWCR */
typedef struct {
    uint8_t twie  : 1;  //!< Two Wire Interrupt Enable
    uint8_t rsvd  : 1;  //!< Reserved
    uint8_t twen  : 1;  //!< Two Wire Enable
    uint8_t twwc  : 1;  //!< Two Wire Write Collision Flag
    uint8_t twsto : 1;  //!< Two Wire Stop Condition
    uint8_t twsta : 1;  //!< Two Wire Start Condition
    uint8_t twea  : 1;  //!< Two Wire Enable Acknowledge
    uint8_t twint : 1;  //!< Two Wire Interrupt
} Atm128I2CControl_s;
typedef union {
    Atm128I2CControl_s bits;
    uint8_t flat;
} Atm128I2CControl_t;

/** I2C Status Codes */
enum {
    ATM128_I2C_BUSERROR	        = 0x00,
    ATM128_I2C_START		= 0x08,
    ATM128_I2C_RSTART		= 0x10,
    ATM128_I2C_MW_SLA_ACK	= 0x18,
    ATM128_I2C_MW_SLA_NACK	= 0x20,
    ATM128_I2C_MW_DATA_ACK	= 0x28,
    ATM128_I2C_MW_DATA_NACK	= 0x30,
    ATM128_I2C_M_ARB_LOST	= 0x38,
    ATM128_I2C_MR_SLA_ACK	= 0x40,
    ATM128_I2C_MR_SLA_NACK	= 0x48,
    ATM128_I2C_MR_DATA_ACK	= 0x50,
    ATM128_I2C_MR_DATA_NACK	= 0x58
};

/** I2C Status Register -- TWSR */
typedef union {
  struct Atm128I2CStatus_s {
    uint8_t twps  : 2;  //!< Two Wire Prescaler Bits
    uint8_t rsvd  : 1;  //!< Reserved
    uint8_t tws   : 5;  //!< Two Wire Status
  } bits;
  uint8_t flat;
} Atm128I2CStatus_t;

/** I2C Slave Address Register -- TWAR */
typedef union {
  struct Atm128I2CSlaveAddr_s {
    uint8_t twgce : 1;  //!< Two Wire General Call Enable
    uint8_t twa   : 7;  //!< Two Wire Slave Address
  } bits;
  uint8_t flat;
} Atm128I2CSlaveAddr_t;

#define avr_i2c_enable()           TWCR |= (1 << TWEN)
#define avr_i2c_start()            TWCR |= (1 << TWSTA) | (1 << TWINT)
#define avr_i2c_wait()	           while(!(TWCR & (1<<TWINT))) ;

#endif // _H_Atm128I2C_h
