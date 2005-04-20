/// $Id: ATm128SPI.h,v 1.1.2.1 2005-04-20 18:32:49 mturon Exp $

/**
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

#ifndef _H_ATm128SPI_h
#define _H_ATm128SPI_h

//====================== SPI Bus ==================================

enum {
    ATM128_SPI_CLK_DIVIDE_4 = 0,
    ATM128_SPI_CLK_DIVIDE_16 = 1,
    ATM128_SPI_CLK_DIVIDE_64 = 2,
    ATM128_SPI_CLK_DIVIDE_128 = 3,
}

/** SPI Control Register */
typedef struct
{
    uint8_t spr   : 2;  //!< SPI Clock Rate
    uint8_t cpha  : 1;  //!< SPI Clock Phase
    uint8_t cpol  : 1;  //!< SPI Clock Polarity
    uint8_t mstr  : 1;  //!< SPI Master/Slave Select
    uint8_t dord  : 1;  //!< SPI Data Order
    uint8_t spe   : 1;  //!< SPI Enable
    uint8_t spie  : 1;  //!< SPI Interrupt Enable
} ATm128SPIControl_t;

typedef ATm128SPIControl_t ATm128_SPCR_t;  //!< SPI Control Register

/** SPI Status Register */
struct {
    uint8_t spi2x : 1;  //!< SPI Parity Error
    uint8_t rsvd  : 5;  //!< Reserved
    uint8_t wcol  : 1;  //!< SPI Write COLision flag
    uint8_t spif  : 1;  //!< SPI Interrupt Flag
} ATm128SPIStatus_t;

typedef ATm128SPIStatus_t ATm128_SPSR_t;  //!< SPI Status Register

typedef uint8_t ATm128_SPDR_t;  //!< SPI Data Register

#endif //_H_ATm128SPI_h

