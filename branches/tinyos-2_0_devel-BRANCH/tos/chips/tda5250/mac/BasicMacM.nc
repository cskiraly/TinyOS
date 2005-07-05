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
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, 
 * OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY 
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT 
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE 
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * - Revision -------------------------------------------------------------
 * $Revision: 1.1.2.1 $
 * $Date: 2005-07-05 19:35:01 $
 * ========================================================================
 */
 
/**
 * PacketSerializerM module
 *
 * @author Kevin Klues <klues@tkn.tu-berlin.de>
 */  

module BasicMacM {
   provides {
      interface Init;
      interface RadioByteComm;
      interface PhyPacketTx;
      interface PhyPacketRx;
   }
   uses {
      interface TDA5250Control;
      interface RadioByteComm as TDA5250RadioByteComm;
      interface PhyPacketTx as TDA5250PhyPacketTx;
      interface PhyPacketRx as TDA5250PhyPacketRx;
   }
}
implementation 
{
   /**************** Module Global Variables  *****************/
   bool txCancel;

   /**************** Radio Init  *****************/
   command error_t Init.init(){
      atomic {
         txCancel = FALSE;
      }
      return SUCCESS;
   }    
   
   async command void PhyPacketTx.sendHeader(uint8_t length_value) {
     call TDA5250PhyPacketTx.sendHeader(length_value);
   }
   
   async command void RadioByteComm.txByte(uint8_t data) {
     call TDA5250RadioByteComm.txByte(data);
   }
   
   async command bool RadioByteComm.isTxDone() {
     return call TDA5250RadioByteComm.isTxDone();
   }   
   
   async command void PhyPacketTx.sendFooter() {
     call TDA5250PhyPacketTx.sendFooter();
   }

   /**************** Radio Recv ****************/
   async command void PhyPacketRx.recvHeader() {
     call TDA5250PhyPacketRx.recvHeader();
   }
   
   async command void PhyPacketRx.recvFooter() {
     call TDA5250PhyPacketRx.recvFooter();
   }      
   
   async command error_t PhyPacketTx.cancel() {
      return call TDA5250PhyPacketTx.cancel();
   }   
   
   async event void TDA5250PhyPacketTx.sendHeaderDone(error_t error) {
     signal PhyPacketTx.sendHeaderDone(error);
   }
   
   /**************** Rx Done ****************/
   async event void TDA5250RadioByteComm.txByteReady(error_t error) {
     signal RadioByteComm.txByteReady(error);    
   }
   
  async event void TDA5250PhyPacketTx.sendFooterDone(error_t error) {
     signal PhyPacketTx.sendFooterDone(error);
  }
  
   async event void TDA5250PhyPacketRx.recvHeaderDone(uint8_t length_value) {
     signal PhyPacketRx.recvHeaderDone(length_value);
   }  
   
   /**************** Rx Done ****************/
   async event void TDA5250RadioByteComm.rxByteReady(uint8_t data) {
      signal RadioByteComm.rxByteReady(data);
   }   
   
   async event void TDA5250PhyPacketRx.recvFooterDone(bool error) {
     signal PhyPacketRx.recvFooterDone(error);
   }
   
  async event void TDA5250Control.TxModeDone(){
  }
  async event void TDA5250Control.TimerModeDone(){     
  }
  async event void TDA5250Control.SelfPollingModeDone(){         
  }  
  async event void TDA5250Control.RxModeDone(){ 
  }
  async event void TDA5250Control.SleepModeDone(){ 
  }
  async event void TDA5250Control.CCAModeDone(){ 
  }
  async event void TDA5250Control.PWDDDInterrupt() {
  }   
}
