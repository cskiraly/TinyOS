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
 * $Date: 2005-05-20 12:54:14 $
 * @author Kevin Klues (klues@tkn.tu-berlin.de)
 * ========================================================================
 */
 
module HPLTDA5250RadioCommM {
  provides {
    interface Init;
    interface HPLTDA5250RegComm;
    interface HPLTDA5250Data;
  }
  uses {
    interface HPLUSARTControl as USARTControl;
    interface HPLUSARTFeedback as USARTFeedback;
    interface GeneralIO as BUSM;
    interface GeneralIO as ENTDA;
    interface GeneralIO as DATA;    
  }
}

implementation {
   /****************************************************************
                      Internal Functions Declared 
   *****************************************************************/
   void transmitByte(uint8_t data);     
   
   
   command error_t Init.init() {
     // setting pins to output
     call BUSM.makeOutput();
     call ENTDA.makeOutput();
     call DATA.makeOutput();       
     
     // initializing pin values
     call BUSM.set();
     call ENTDA.set();
     call DATA.clr();
     
     // reverse data direction since default of radio
       //is receive
     call DATA.makeInput();           
     return SUCCESS;
   }   
   
   async command error_t HPLTDA5250Data.tx(uint8_t data) {
     call USARTControl.tx(data);
     return SUCCESS;
   }
   
   async command bool HPLTDA5250Data.isTxDone() {
     return call USARTControl.isTxEmpty();
   }   
   
   async command error_t HPLTDA5250Data.enableTx() {   
     call USARTControl.setClockSource(SSEL_SMCLK);
     call USARTControl.setClockRate(UBR_SMCLK_38400, UMCTL_SMCLK_38400); 
     call USARTControl.setModeUART_TX();            
     call USARTControl.enableTxIntr();
     return SUCCESS;
   }   
   
   async command error_t HPLTDA5250Data.disableTx() {
     call USARTControl.disableUARTTx();
     return SUCCESS;
   }         
   
   async command error_t HPLTDA5250Data.enableRx() {  
     call USARTControl.setClockSource(SSEL_SMCLK);
     call USARTControl.setClockRate(UBR_SMCLK_38400, UMCTL_SMCLK_38400);   
     call USARTControl.setModeUART_RX();      
     call USARTControl.enableRxIntr();   
     return SUCCESS;
   }   
   
   async command error_t HPLTDA5250Data.disableRx() {
     call USARTControl.disableUARTRx();
     return SUCCESS;
   }      
   
   async event void USARTFeedback.txDone() {
     signal HPLTDA5250Data.txReady();
   }
   
   async event void USARTFeedback.rxOverflow() {
   }
   
   async event void USARTFeedback.rxDone(uint8_t data) {
     signal HPLTDA5250Data.rxDone(data);
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

   async command void HPLTDA5250RegComm.writeByte(uint8_t address, uint8_t data) {
      msp430_usartmode_t mode = call USARTControl.getMode();   
      call USARTControl.setModeSPI(); 
      call ENTDA.clr();
      transmitByte(address);
      transmitByte(data);
      while (call USARTControl.isTxEmpty() == FAIL);
      call ENTDA.set();
      call USARTControl.setMode(mode); 
   } 

   async command void HPLTDA5250RegComm.writeWord(uint8_t address, uint16_t data) {
      msp430_usartmode_t mode = call USARTControl.getMode();   
      call USARTControl.setModeSPI();   
      call ENTDA.clr();
      transmitByte(address);
      transmitByte((uint8_t) (data >> 8));
      transmitByte((uint8_t) data);
      while (call USARTControl.isTxEmpty() == FALSE);
      call ENTDA.set();
      call USARTControl.setMode(mode);
      return;
   }

   async command uint8_t HPLTDA5250RegComm.readByte(uint8_t address){
      call HPLTDA5250RegComm.writeByte(address, 0x00);  
      return call USARTControl.rx();
   }
   
   default async event void HPLTDA5250Data.txReady() {}
   default async event void HPLTDA5250Data.rxDone(uint8_t data) {}
}
