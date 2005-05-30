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
 * $Date: 2005-05-30 19:49:54 $
 * @author Kevin Klues (klues@tkn.tu-berlin.de)
 * ========================================================================
 */
 
module MSP430TDA5250RegCommM {
  provides {
    interface Init;
    interface TDA5250RegComm; 
    interface Resource;
  }
  uses {
    interface GeneralIO as BUSM;     
    interface GeneralIO as DATA;
    interface Resource as SPIResource;
    interface ResourceUser;   
    interface HPLUSARTControl as USARTControl;
  }
}

implementation {
   
   command error_t Init.init() {
     // setting pins to output
     call BUSM.makeOutput();
     
     //initializing pin values
     call BUSM.set();  //Use SPI for writing to Regs
    
     return SUCCESS;
   }   
   
   async command error_t Resource.request() {
     return call SPIResource.request(); 
   } 
   
   async command error_t Resource.immediateRequest() {
     if(call SPIResource.immediateRequest() == EBUSY)
       return EBUSY;
     call USARTControl.setModeSPI();
     return SUCCESS;
   }   
   
   async command void Resource.release() {
     call SPIResource.release(); 
   }
   
   event void SPIResource.granted() {
     call USARTControl.setModeSPI();
     signal Resource.granted();
   }
   
   event void SPIResource.requested() {
     signal Resource.requested();
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
}
