/* $Id: HalPXA27xI2CMasterM.nc,v 1.1.2.1 2006-02-01 23:54:24 philipb Exp $ */
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

generic module HalPXA27xI2CM()
{
  provides interface Init;
  provides interface I2CPacket;

  uses interface HplPXA27xI2C as I2C;

}

implementation
{

  command error_t Init.init() {

  }

  async command result_t I2CPacket.readPacket(uint16_t addr, uint8_t length, uint8_t* data) {

  }

  async command result_t I2CPacket.writePacket(uint16_t addr, uint8_t length, uint8_t* data) {

  }

  async event void I2C.interruptI2C() {

    return;
  }

  default async event void I2CPacket.readPacketDone(uint16_t addr, uint8_t length, 
						    uint8_t* data, result_t success) {
    return;
  }

  default async event void I2CPacket.writePacketDone(uint16_t addr, uint8_t length, 
						     uint8_t* data, result_t success) { 
    return;
  }
}
