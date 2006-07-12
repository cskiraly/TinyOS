/* $Id: HalPXA27xSerialP.nc,v 1.1.2.2 2006-07-12 19:09:59 philipb Exp $ */
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
/*
 *  Intel Open Source License
 *
 *  Copyright (c) 2002 Intel Corporation
 *  All rights reserved.
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions are
 *  met:
 *
 *	Redistributions of source code must retain the above copyright
 *  notice, this list of conditions and the following disclaimer.
 *	Redistributions in binary form must reproduce the above copyright
 *  notice, this list of conditions and the following disclaimer in the
 *  documentation and/or other materials provided with the distribution.
 *      Neither the name of the Intel Corporation nor the names of its
 *  contributors may be used to endorse or promote products derived from
 *  this software without specific prior written permission.
 *
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 *  ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 *  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 *  PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE INTEL OR ITS
 *  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 *  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 *  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 *  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 *  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 *  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 *  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 *
 */
/**
 * Implements the SerialByteComm interface over an 8,N,1 configuration
 * of a PXA27x UART usingin PIO. 
 *
 * @param defaultRate Default baud rate for the serial port. 
 *
 *
 * @author Phil Buonadonna
 */

#include "pxa27x_serial.h"

generic module HalPXA27xSerialP(uint32_t defaultRate)
{
  provides {
    interface Init;
    interface StdControl;
    interface SerialByteComm;
    interface HalPXA27xSerialPacket;
    interface HalPXA27xSerialCntl;
  }
  uses {
    interface Init as UARTInit;
    interface HplPXA27xUART as UART;
    interface HplPXA27xDMAChnl as RxDMA;
    interface HplPXA27xDMAChnl as TxDMA;
    interface HplPXA27xDMAInfo as UARTRxDMAInfo;
    interface HplPXA27xDMAInfo as UARTTxDMAInfo;
  }
}

implementation 
{

  uint8_t *txCurrentBuf, *rxCurrentBuf;
  uint32_t lenCurrent;

  command error_t Init.init() {
    error_t error = SUCCESS;
#if 0
    uint32_t uiDivisor;
    if (defaultRate == 0) {
      return EINVAL;
    }

    uiDivisor = 921600/defaultRate;
    // Check for invalid baud rate divisor value.
    // XXX - Eventually could use '0' to imply auto rate detection
    if ((uiDivisor & 0xFFFF0000) || (uiDivisor == 0)) {
      return EINVAL;
    }

    atomic {
      call UARTInit.init();    
      call UART.setDLL((uiDivisor & 0xFF));
      call UART.setDLH(((uiDivisor >> 8) & 0xFF));
      call UART.setLCR(LCR_WLS(3));
      call UART.setMCR(MCR_OUT2);
      //call UART.setIER(IER_RAVIE | IER_TIE | IER_UUE);
      call UART.setFCR(FCR_TRFIFOE);
    }
#endif

    atomic {
      call UARTInit.init();
    }
    error = call HalPXA27xSerialCntl.configPort(defaultRate,8,NONE,1,FALSE);
    return error;
  }

  command error_t StdControl.start() {
    atomic {
      call UART.setIER(IER_RAVIE | IER_TIE | IER_UUE);
    }
    return SUCCESS;
  }

  command error_t StdControl.stop() {
    atomic {
      call UART.setIER(0);
    }
    return SUCCESS;
  }

  async command error_t SerialByteComm.put(uint8_t data) {
    atomic call UART.setTHR(data);
    return SUCCESS;
  }

  async command error_t HalPXA27xSerialPacket.send(uint8_t *buf, uint16_t len) {

    uint32_t tmp;
    uint32_t txAddr;
    uint32_t DMAFlags;
    error_t error = FAIL;

    atomic {
      txCurrentBuf = buf;
      lenCurrent = len;
    }

    DMAFlags = (DCMD_FLOWTRG | DCMD_BURST8 | DCMD_WIDTH1 
		  | DCMD_LEN(len));

    txAddr = (uint32_t) buf;
    txDMAFlags |= DCMD_INCSRCADDR;

    call TxDMA.setDCSR(DCSR_NODESCFETCH);
    call TxDMA.setDSADR(txAddr);
    call TxDMA.setDTADR(call UARTTxDMAInfo.getAddr());
    call TxDMA.setDCMD(DMAFlags);
    
    call UART.setIER(IER_DMAE);
    
    call TxDMA.setDCSR(DCSR_RUN | DCSR_NODESCFETCH);
    
    error = SUCCESS;
    
    return error;
  }


  async command error_t HalPXA27xSerialPacket.receive(uint8_t *buf, uint16_t len, 
						      uint16_t timeout) {


  }
  
  async event void RxDMA.interruptDMA() {

  }

  async event void TxDMA.interruptDMA() {

  }


  async command error_t HalPXA27xSerialCntl.configPort(uint32_t baudrate, 
							uint8_t databits, 
							enum parity, 
							uint8_t stopbits, 
							bool flow_cntl) {
    uint32_t uiDivisor;
    uint32_t valLCR = 0;
    uint32_t valMCR = MCR_OUT2;
      
    uiDivisor = 921600/baudrate;
    // Check for invalid baud rate divisor value.
    // XXX - Eventually could use '0' to imply auto rate detection
    if ((uiDivisor & 0xFFFF0000) || (uiDivisor == 0)) {
      return EINVAL;
    }

    if ((databits > 8 || databits < 5)) {
      return EINVAL;
    }
    valLCR |= LCR_WLS((databits-5));

    switch (parity) {
    case EVEN: 
      valLCR |= LCR_EPS;
      // Fall through to enable
    case ODD:
      valLCR |= LCR_PEN;
      break;
    case NONE:
      break;
    default:
      return EINVAL;
      break;
    }
    
    if ((stopbits > 2) || (stopbits < 1)) {
      return EINVAL;
    }
    else if (stopbits == 2) {
      valLCR |= LCR_STB;
    }

    if (flow_cntl) {
      valMCR |= MCR_AFE;
    }

    atomic {
      call UART.setDLL((uiDivisor & 0xFF));
      call UART.setDLH(((uiDivisor >> 8) & 0xFF));
      call UART.setLCR(valLCR);
      call UART.setMCR(valMCR);
    }
 
  }
    
  async command error_t HplPXA27xSerialCntl.flushPort() {

    atomic {
      call UART.setFCR(FCR_RESETTF | FCR_RESETRF);
    }

    return SUCCESS;
  }
  
  async event void UART.interruptUART() {
    uint8_t error, intSource;
    
    intSource = call UART.getIIR() & IIR_IID_MASK;
    intSource = intSource >> 1;
    
    switch (intSource) {
    case 0: // MODEM STATUS
      break;
    case 1: // TRANSMIT FIFO
      signal SerialByteComm.putDone();
      break;
    case 2: // RECEIVE FIFO data available
      while (call UART.getLSR() & LSR_DR) {
	signal SerialByteComm.get(call UART.getRBR());
      }
      break;
    case 3: // ERROR
      error = call UART.getLSR();
      break;
    default:
      break;
    }
    return;
  }

  default async event void SerialByteComm.get(uint8_t data) { return; }

  default async event void SerialByteComm.putDone() { return; }

  default async event uint8_t* HalPXA27xSerialPacket.sendDone(uint8_t *buf, 
							      uint16_t len, 
							      uart_status_t status) {
    return NULL;
  }

  default async event uint8_t* HalPXA27xSerialPacket.receiveDone(uint8_t *buf, 
								 uint16_t len, 
								 uart_status_t status) {
    return NULL;
  }


}
