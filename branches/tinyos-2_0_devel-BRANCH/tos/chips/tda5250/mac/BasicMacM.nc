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
 * $Revision: 1.1.2.2 $
 * $Date: 2005-07-05 22:59:07 $
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
      interface SplitControl as RadioSplitControl;
      interface Timer<TMilli> as RxTimeoutTimer;      
      interface RadioByteComm as TDA5250RadioByteComm;
      interface PhyPacketTx as TDA5250PhyPacketTx;
      interface PhyPacketRx as TDA5250PhyPacketRx;
   }
}
implementation 
{
   /**************** Module Global Variables  *****************/
   uint8_t length;
   bool txBusy, rxBusy;

   /**************** Radio Init  *****************/
   command error_t Init.init(){
      atomic txBusy = FALSE;
      return SUCCESS;
   }    
   
  event void RadioSplitControl.startDone(error_t error) {
    call TDA5250Control.RxMode();  
  }
  
  event void RadioSplitControl.stopDone(error_t error) {
    call RxTimeoutTimer.stop();
  }    
   
   async command void PhyPacketTx.sendHeader(uint8_t length_value) {
     if(txBusy == TRUE || rxBusy == TRUE) {
       signal PhyPacketTx.sendHeaderDone(EBUSY);
       return;
     }
     atomic {
       length = length_value;
       txBusy = TRUE;
     }
     if(call TDA5250Control.TxMode() != SUCCESS)
       signal PhyPacketTx.sendHeaderDone(FAIL);
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
     if(error != SUCCESS)
       atomic txBusy = FALSE;
     signal PhyPacketTx.sendHeaderDone(error);
   }
   
   /**************** Rx Done ****************/
   async event void TDA5250RadioByteComm.txByteReady(error_t error) {
     if(error != SUCCESS)
       atomic txBusy = FALSE;   
     signal RadioByteComm.txByteReady(error);    
   }
   
  async event void TDA5250PhyPacketTx.sendFooterDone(error_t error) {
    call TDA5250Control.RxMode();
    atomic txBusy = FALSE;
    signal PhyPacketTx.sendFooterDone(error);
  }
  
   async event void TDA5250PhyPacketRx.recvHeaderDone(uint8_t length_value) {
     atomic rxBusy = TRUE;
     call RxTimeoutTimer.startOneShotNow((((TOSH_DATA_LENGTH+2)*100)/(384)+1));
     signal PhyPacketRx.recvHeaderDone(length_value);
   }  
   
   event void RxTimeoutTimer.fired() {
     if(rxBusy == FALSE)
       return;
     atomic rxBusy = FALSE;
     call TDA5250PhyPacketRx.recvHeader();
   }
   
   /**************** Rx Done ****************/
   async event void TDA5250RadioByteComm.rxByteReady(uint8_t data) {
      signal RadioByteComm.rxByteReady(data);
   }   
   
   async event void TDA5250PhyPacketRx.recvFooterDone(bool error) {
     atomic rxBusy = FALSE;
     call TDA5250PhyPacketRx.recvHeader();
     signal PhyPacketRx.recvFooterDone(error);
   }
   
  async event void TDA5250Control.TxModeDone(){
    call TDA5250PhyPacketTx.sendHeader(length);  
  }
  async event void TDA5250Control.TimerModeDone(){     
  }
  async event void TDA5250Control.SelfPollingModeDone(){         
  }  
  async event void TDA5250Control.RxModeDone(){ 
    call TDA5250PhyPacketRx.recvHeader();
  }
  async event void TDA5250Control.SleepModeDone(){ 
  }
  async event void TDA5250Control.CCAModeDone(){ 
  }
  async event void TDA5250Control.PWDDDInterrupt() {
  }   
}
