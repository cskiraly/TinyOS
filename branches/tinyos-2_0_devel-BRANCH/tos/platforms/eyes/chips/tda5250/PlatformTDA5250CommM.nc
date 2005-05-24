/*
 * Copyright (c) 2004, Technische Universitaet Berlin
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
 * - Neither the name of the Technische Universitaet Berlin nor the names
 *   of its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES {} LOSS OF USE, DATA,
 * OR PROFITS {} OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * - Description ---------------------------------------------------------
 * - Revision -------------------------------------------------------------
 * $Revision: 1.1.2.1 $
 * $Date: 2005-05-24 16:21:09 $
 * @author Kevin Klues (klues@tkn.tu-berlin.de)
 * ========================================================================
 */
 
module PlatformTDA5250CommM {
  provides {
    interface Init;
    interface TDA5250RegComm;
    interface TDA5250DataComm;
    interface TDA5250DataControl;   
    interface Resource as RegResource;
    interface Resource as DataResource;
  }
  uses {
    interface GeneralIO as BUSM;     
    interface GeneralIO as DATA;
    interface Resource as SPIResource;
    interface Resource as UARTResource; 
    interface ResourceUser;   
    interface HPLUSARTControl as USARTControl;
    interface HPLUSARTFeedback as USARTFeedback;
  }
}

implementation {
   
   command error_t Init.init() {
     // setting pins to output
     call BUSM.makeOutput();
     call DATA.makeOutput(); 
     
     //initializing pin values
     call BUSM.set();  //Use SPI for writing to Regs
     call DATA.clr();  //Clear the data line
       
     //Make data an input
     call DATA.makeInput();
    
     return SUCCESS;
   }   
   
   async command error_t RegResource.request() {
     return call SPIResource.request(); 
   }
   
   async command error_t DataResource.request() {
     return call UARTResource.request(); 
   }   
   
   async command error_t RegResource.immediateRequest() {
     if(call SPIResource.immediateRequest() == EBUSY)
       return EBUSY;
     call USARTControl.setModeSPI();
     return SUCCESS;
   }
   
   async command error_t DataResource.immediateRequest() {
     if(call UARTResource.immediateRequest() == EBUSY)
       return EBUSY;
     call USARTControl.setModeUART();
     return SUCCESS;
   }    
   
   async command void RegResource.release() {
     call SPIResource.release(); 
   }
   
   async command void DataResource.release() {
     call UARTResource.release(); 
   }      
   
   event void SPIResource.granted() {
     call USARTControl.setModeSPI();
     signal RegResource.granted();
   }
   
   event void UARTResource.granted() {
     call USARTControl.setModeUART();
     signal DataResource.granted();
   }    
   
   event void UARTResource.requested() {
     signal DataResource.requested();
   }   
   
   event void SPIResource.requested() {
     signal RegResource.requested();
   }   
   
   async command error_t TDA5250DataComm.tx(uint8_t data) {
     if(call ResourceUser.user() != TDA5250_UART_BUS_ID)
       return FAIL;   
     call USARTControl.tx(data);
     return SUCCESS;
   }
   
   async command bool TDA5250DataComm.isTxDone() {
     if(call ResourceUser.user() != TDA5250_UART_BUS_ID)
       return FAIL;   
     return call USARTControl.isTxEmpty();
   }   
   
   async command error_t TDA5250DataControl.enableTx() {   
     if(call ResourceUser.user() != TDA5250_UART_BUS_ID)
       return FAIL;
     call USARTControl.setClockSource(SSEL_SMCLK);
     call USARTControl.setClockRate(UBR_SMCLK_38400, UMCTL_SMCLK_38400); 
     call USARTControl.setModeUART_TX();            
     call USARTControl.enableTxIntr();
     return SUCCESS;
   }   
   
   async command error_t TDA5250DataControl.disableTx() {
     if(call ResourceUser.user() != TDA5250_UART_BUS_ID)
       return FAIL;   
     call USARTControl.disableUARTTx();
     return SUCCESS;
   }         
   
   async command error_t TDA5250DataControl.enableRx() {  
     if(call ResourceUser.user() != TDA5250_UART_BUS_ID)
       return FAIL;   
     call USARTControl.setClockSource(SSEL_SMCLK);
     call USARTControl.setClockRate(UBR_SMCLK_38400, UMCTL_SMCLK_38400);   
     call USARTControl.setModeUART_RX();      
     call USARTControl.enableRxIntr();   
     return SUCCESS;
   }   
   
   async command error_t TDA5250DataControl.disableRx() {
     if(call ResourceUser.user() != TDA5250_UART_BUS_ID)
       return FAIL;   
     call USARTControl.disableUARTRx();
     return SUCCESS;
   }      
   
   async event void USARTFeedback.txDone() {
     if(call ResourceUser.user() != TDA5250_UART_BUS_ID)
       return;   
     signal TDA5250DataComm.txReady();
   }
   
   async event void USARTFeedback.rxOverflow() {
   }
   
   async event void USARTFeedback.rxDone(uint8_t data) {
     if(call ResourceUser.user() != TDA5250_UART_BUS_ID)
       return;   
     signal TDA5250DataComm.rxDone(data);
   }  
   
   /****************************************************************
                    Internal Functions Implemented
   *****************************************************************/
   
   /* Reading and writing to the radio over the USART */
   void transmitByte(uint8_t data) {
      call USARTControl.tx(data);
      while (call USARTControl.isTxIntrPending() == FALSE);
      call USARTControl.clrTxIntr();
   }

   async command error_t TDA5250RegComm.writeByte(uint8_t address, uint8_t data) {  
     if(call ResourceUser.user() != TDA5250_SPI_BUS_ID)
       return FAIL;     
      call USARTControl.setModeSPI();       
      transmitByte(address);
      transmitByte(data);
      while (call USARTControl.isTxEmpty() == FAIL);
      return SUCCESS;
   } 

   async command error_t TDA5250RegComm.writeWord(uint8_t address, uint16_t data) {  
     if(call ResourceUser.user() != TDA5250_SPI_BUS_ID)
       return FAIL;        
      call USARTControl.setModeSPI();       
      transmitByte(address);
      transmitByte((uint8_t) (data >> 8));
      transmitByte((uint8_t) data);
      while (call USARTControl.isTxEmpty() == FALSE);
      return SUCCESS;
   }

   async command uint8_t TDA5250RegComm.readByte(uint8_t address){
     if(call ResourceUser.user() != TDA5250_SPI_BUS_ID)
       return 0x00;   
      call TDA5250RegComm.writeByte(address, 0x00);  
      return call USARTControl.rx();
   }
   
   default event void RegResource.granted() {}
   default event void RegResource.requested() {}   
   default event void DataResource.granted() {}
   default event void DataResource.requested() {}    
   default async event void TDA5250DataComm.txReady() {}
   default async event void TDA5250DataComm.rxDone(uint8_t data) {}
}
