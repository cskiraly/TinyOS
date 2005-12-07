/* $Id: HalPXA27xSpiPioM.nc,v 1.1.2.1 2005-12-07 23:10:40 philipb Exp $ */
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
 * I'm plements the TOS 2.0 SPIByte and SPIPacket interfaces for the PXA27x.
 * It assumes the Motorola Serial Peripheral Interface format.
 * Uses DMA for the packet based transfers.
 * 
 * @param valSCR The value for the SCR field in the SSCR0 register of the 
 * associated SSP peripheral.
 *
 * @param valDSS The value for the DSS field in the SSCR0 register of the
 * associated SSP peripheral.
 * 
 * @author Phil Buonadonna
 */

generic module HalPXA27xSpiPioM(uint8_t valSCR, uint8_t valDSS) 
{
  provides {
    interface Init;
    interface SPIByte;
    interface SPIPacket[uint8_t instance];
  }
  uses {
    interface HplPXA27xSSP as SSP;
    //interface HplPXA27xDMAChnl as RxDMA;
    //interface HplPXA27xDMAChnl as TxDMA;
    //interface HplPXA27xDMAInfo as SSPRxDMAInfo;
    //interface HplPXA27xDMAInfo as SSPTxDMAInfo;
  }
}

implementation
{
  // The BitBuckets need to be 8 bytes. 
  norace unsigned long long txBitBucket, rxBitBucket;
  uint8_t *txCurrentBuf, *rxCurrentBuf;
  uint8_t instanceCurrent;
  uint32_t lenCurrent;

  task void SpiPacketDone() {
    uint8_t *txBuf,*rxBuf;
    uint8_t instance;
    uint32_t len;
    
    atomic {
      instance = instanceCurrent;
      len = lenCurrent;
      txBuf = txCurrentBuf;
      rxBuf = rxCurrentBuf;
      lenCurrent = 0;
      signal SPIPacket.sendDone[instance](txBuf,rxBuf,len,SUCCESS);
    }
    
    return;
  }

  command error_t Init.init() {

    txBitBucket = 0, rxBitBucket = 0;
    txCurrentBuf = rxCurrentBuf = NULL;
    lenCurrent = 0 ;
    instanceCurrent = 0;

    call SSP.setSSCR1(0 /*(SSCR1_TRAIL | SSCR1_RFT(8) | SSCR1_TFT(8))*/);
    call SSP.setSSTO(96*8);
    call SSP.setSSCR0(SSCR0_SCR(/*1*/ valSCR) | SSCR0_SSE | SSCR0_FRF(0) | SSCR0_DSS(/*0x7*/ valDSS) );

    //call TxDMA.setMap(call SSPTxDMAInfo.getMapIndex());
    //call RxDMA.setMap(call SSPRxDMAInfo.getMapIndex());
    //call TxDMA.setDALGNbit(TRUE);
    //call RxDMA.setDALGNbit(TRUE);

    //call RxDMA.setDSADR(call SSPRxDMAInfo.getAddr());
    //call TxDMA.setDTADR(call SSPTxDMAInfo.getAddr());
    return SUCCESS;
  }

  async command error_t SPIByte.write(uint8_t tx, uint8_t* rx) {
    volatile uint32_t tmp;
    volatile uint8_t val;
#if 1
    while ((call SSP.getSSSR()) & SSSR_RNE) {
      tmp = call SSP.getSSDR();
    } 
#endif
    call SSP.setSSDR(tx); 

    while ((call SSP.getSSSR()) & SSSR_BSY);

    val = call SSP.getSSDR();

    if (rx != NULL) *rx = val;

    return SUCCESS;
  }

  async command error_t SPIPacket.send[uint8_t instance](uint8_t* txBuf, uint8_t* rxBuf, uint8_t len) {
    uint32_t tmp,i;
    uint8_t *txPtr,*rxPtr;
    uint32_t txInc = 1,rxInc = 1;
    error_t error = FAIL;

#if 1
    while ((call SSP.getSSSR()) & SSSR_RNE) {
      tmp = call SSP.getSSDR();
    }
#endif 

    atomic {
      txCurrentBuf = txBuf;
      rxCurrentBuf = rxBuf;
      lenCurrent = len;
      instanceCurrent = instance;
    }

    if (rxBuf == NULL) { 
      rxPtr = (uint8_t *)&rxBitBucket; 
      rxInc = 0;
    }
    else {
      rxPtr = rxBuf; 
    }

    if (txBuf == NULL) {
      txPtr = (uint8_t *)&txBitBucket; 
      txInc = 0;
    }
    else {
      txPtr = txBuf;
    }

    while (len > 16) {
      for (i = 0;i < 16; i++) {
	call SSP.setSSDR(*txPtr);
	txPtr += txInc;
      }
      while (call SSP.getSSSR() & SSSR_BSY);
      for (i = 0;i < 16;i++) {
	*rxPtr = call SSP.getSSDR();
	rxPtr += rxInc;
      }
      len -= 16;
    }
    for (i = 0;i < len; i++) {
      call SSP.setSSDR(*txPtr);
      txPtr += txInc;
    }
    while (call SSP.getSSSR() & SSSR_BSY);
    for (i = 0;i < len;i++) {
      *rxPtr = call SSP.getSSDR();
      rxPtr += rxInc;
    }

    post SpiPacketDone();

    error = SUCCESS;
    
    return error;
  }
  
  async event void SSP.interruptSSP() {
    // For this Hal, we should never get here normally
    // Perhaps we should signal any weird errors? For now, just clear the interrupts
    call SSP.setSSSR(SSSR_BCE | SSSR_TUR | SSSR_EOC | SSSR_TINT | 
			       SSSR_PINT | SSSR_ROR );
    return;
  }

  default async event void SPIPacket.sendDone[uint8_t instance](uint8_t* txBuf, uint8_t* rxBuf, 
					      uint8_t len, error_t error) {
    return;
  }
  
}
