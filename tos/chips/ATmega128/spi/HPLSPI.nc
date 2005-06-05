/// $Id: HPLSPI.nc,v 1.1.2.2 2005-06-05 00:10:27 mturon Exp $

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

#include <ATm128SPI.h>

interface HPLSPI
{
    async command uint8_t read();
    async command void    write(uint8_t data);
    async event   void    dataReady(uint8_t data);

    async command bool isBusy();
    async command error_t sleep();

    // General access to control registers
    async command ATm128SPIControl_t getControl();
    async command ATm128SPIStatus_t  getStatus();
    async command void               setControl(ATm128SPIControl_t ctrl);
    async command void               setStatus(ATm128SPIStatus_t stts);

    // Slave control
    async command error_t slaveInit();
    async command error_t slaveTx();
    async command error_t slaveRx();

    // Master control
    async command error_t masterInit();
    async command error_t masterTx();
    async command error_t masterRx();
    async command error_t masterStart();
    async command error_t masterStop();

    // Command control utilities
    async command error_t setEnable(bool busOn);
    async command bool    getEnable();
    async command error_t setInterrupt(bool enabled);
    async command bool    getInterrupt();
    async command error_t setSpeed(uint8_t speed);
    async command uint8_t getSpeed();
}
