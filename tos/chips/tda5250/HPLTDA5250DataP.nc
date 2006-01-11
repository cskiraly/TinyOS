/*
 * Copyright (c) 2004, Technische Universitat Berlin
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright notice,
 *   this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the distribution.
 * - Neither the name of the Technische Universitat Berlin nor the names
 *   of its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA,
 * OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * - Revision -------------------------------------------------------------
 * $Revision: 1.1.2.2 $
 * $Date: 2006-01-11 20:42:07 $ 
 * ======================================================================== 
 */
 
 /**
 * HPLTDA5250DataM module
 *
 * @author Kevin Klues (klues@tkn.tu-berlin.de)
  */
 
module HPLTDA5250DataP {
  provides {
    interface Init;
    interface HPLTDA5250Data;
    interface Resource;
  }
  uses {
    interface GeneralIO as DATA;     
    interface HplMsp430Usart as Usart;
    interface Resource as UartResource;
    interface ArbiterInfo;
  }
}

implementation {
   
   /****************************************************************
  async commands Implemented
   *****************************************************************/
   /**
   * Initializes the Radio, setting up all Pin configurations
   * to the MicroProcessor that is driving it
   *
   * @return always returns SUCCESS
    */   
  command error_t Init.init() {
     // setting pins to output
    call DATA.makeOutput();
     
     // initializing pin values
    call DATA.clr();
                 
    //Make Rx default
    call DATA.makeInput();  
    return SUCCESS;
  }
         
  async command error_t Resource.request() {
    return call UartResource.request(); 
  } 
   
  async command error_t Resource.immediateRequest() {
    if(call UartResource.immediateRequest() == EBUSY) {
      return EBUSY;
    }
    // Need to put back in once HPLUSART0M is fixed
    //call USARTControl.setModeUART(); 
    return SUCCESS;
  }   
   
  async command void Resource.release() {
    call UartResource.release(); 
  }
  
  async command uint8_t Resource.getId() {
    return TDA5250_UART_BUS_ID;
  }
   
  event void UartResource.granted() {
     // Need to put back in once HPLUSART0M is fixed
    //call USARTControl.setModeUART(); 
    signal Resource.granted();
  }
   
  /* FIXME
  event void UartResource.requested() {
    signal Resource.requested();
  } 
  */
        
  async command error_t HPLTDA5250Data.tx(uint8_t data) {
    if(call ArbiterInfo.userId() != TDA5250_UART_BUS_ID)
      return FAIL;
    call Usart.tx(data);
    return SUCCESS;
  }
  
  async command bool HPLTDA5250Data.isTxDone() {
    if(call ArbiterInfo.userId() != TDA5250_UART_BUS_ID)
      return FAIL;
    return call Usart.isTxEmpty();
  }
         
  async command error_t HPLTDA5250Data.enableTx() {
    if(call ArbiterInfo.userId() != TDA5250_UART_BUS_ID)
      return FAIL;
    call Usart.setClockSource(SSEL_SMCLK);
    call Usart.setClockRate(UBR_SMCLK_38400, UMCTL_SMCLK_38400);
    call Usart.setModeUART_TX();
    call Usart.enableTxIntr();
    return SUCCESS;
  }
         
  async command error_t HPLTDA5250Data.disableTx() {
    if(call ArbiterInfo.userId() != TDA5250_UART_BUS_ID)
      return FAIL;
    call Usart.disableUARTTx();
    return SUCCESS;
  }
         
  async command error_t HPLTDA5250Data.enableRx() {
    if(call ArbiterInfo.userId() != TDA5250_UART_BUS_ID)
      return FAIL;
    call Usart.setClockSource(SSEL_SMCLK);
    call Usart.setClockRate(UBR_SMCLK_38400, UMCTL_SMCLK_38400);
    call Usart.setModeUART_RX();
    call Usart.enableRxIntr(); 
    return SUCCESS;
  }
         
  async command error_t HPLTDA5250Data.disableRx() {
    if(call ArbiterInfo.userId() != TDA5250_UART_BUS_ID)
      return FAIL;
    call Usart.disableUARTRx();
    return SUCCESS;
  }
         
  async event void Usart.txDone() {
    if(call ArbiterInfo.userId() != TDA5250_UART_BUS_ID)
      return;
    signal HPLTDA5250Data.txReady();
  }
         
  /*
  async event void Usart.rxOverflow() {
  }
  */      
  
  async event void Usart.rxDone(uint8_t data) {
    if(call ArbiterInfo.userId() != TDA5250_UART_BUS_ID)
      return;
    signal HPLTDA5250Data.rxDone(data);
  }
        
  default event void Resource.granted() {}
  // FIXME
  //default event void Resource.requested() {}
  default async event void HPLTDA5250Data.txReady() {}
  default async event void HPLTDA5250Data.rxDone(uint8_t data) {}
}
