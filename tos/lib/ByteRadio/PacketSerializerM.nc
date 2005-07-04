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
 * $Date: 2005-07-04 09:28:14 $
 * ========================================================================
 */
 
/**
 * PacketSerializerM module
 *
 * @author Kevin Klues <klues@tkn.tu-berlin.de>
 */  

module PacketSerializerM {
   provides {
      interface Init;
      interface Send;
      interface Receive;
   }
   uses {
      interface RadioByteComm;
      interface PhyPacketTx;
      interface PhyPacketRx;
   }
}
implementation 
{
   /**************** Module Global Variables  *****************/
   uint8_t *txBufPtr;  // pointer to tx buffer
   uint8_t *rxBufPtr;  // pointer to rx buffer
   uint16_t byteCnt;      // index into current data
   uint16_t msgLength;   // Length of message
   bool txCancel;

   /**************** Local Function Declarations  *****************/
   void TransmitNextByte();
   void ReceiveNextByte(uint8_t data);
   
   /**************** Task Declarations  *****************/   
   task void SendDoneSuccessTask() {
     signal Send.sendDone((message_t*)txBufPtr, SUCCESS);
   }
   task void SendDoneCancelTask() {
     signal Send.sendDone((message_t*)txBufPtr, ECANCEL);
   }
   task void SendDoneFailTask() {
     signal Send.sendDone((message_t*)txBufPtr, FAIL);
   }
   task void ReceiveTask() {
     signal Receive.receive((message_t*)rxBufPtr, (void*)rxBufPtr, msgLength);
   }   

   /**************** Radio Init  *****************/
   command error_t Init.init(){
      atomic {
         txBufPtr = NULL;
         rxBufPtr = NULL;
         byteCnt = 0;
         msgLength = 0;
         txCancel = FALSE;
      }     
     return SUCCESS;
   }

   /**************** Radio Send ****************/
   command error_t Send.send(message_t* msg, uint8_t len) {
     atomic {
       txBufPtr = (uint8_t*)msg;
       msgLength = len;
       byteCnt = 0;
       txCancel = FALSE;
     }
     call PhyPacketTx.sendHeader(len);
     return SUCCESS;
   }
	 
	 command error_t Send.cancel(message_t* msg) {
	   if(msg != (message_t*)txBufPtr)
		   return FAIL;
		else return call PhyPacketTx.cancel();
	 }
   
   async event void PhyPacketTx.sendHeaderDone(error_t error) {
     if(error == SUCCESS)
       TransmitNextByte();
     else if(error == ECANCEL)
       post SendDoneCancelTask();        
     else post SendDoneFailTask();
   }
   
   /**************** Rx Done ****************/
   async event void RadioByteComm.txByteReady(error_t error) {
     if(error == SUCCESS)
      TransmitNextByte();
     else if(error == ECANCEL)
       post SendDoneCancelTask();        
     else post SendDoneFailTask();      
   }   
   
  void TransmitNextByte() {
    if(byteCnt == msgLength)
      call PhyPacketTx.sendFooter();
    else call RadioByteComm.txByte(txBufPtr[byteCnt++]);
  }   
   
  async event void PhyPacketTx.sendFooterDone(error_t error) {
     if(error == SUCCESS)
       post SendDoneSuccessTask();
     else if(error == ECANCEL)
       post SendDoneCancelTask();        
     else post SendDoneFailTask();
     call PhyPacketRx.recvHeader();
  }
  
   async event void PhyPacketRx.recvHeaderDone(uint8_t length_value) {
     byteCnt = 0;
   }  
   
   /**************** Rx Done ****************/
   async event void RadioByteComm.rxByteReady(uint8_t data) {
      ReceiveNextByte(data);
   }   
   
   async event void PhyPacketRx.recvFooterDone(bool error) {
     post ReceiveTask();
   }   

  /* Receive the next Byte from the USART */
  void ReceiveNextByte(uint8_t data) {
    rxBufPtr[byteCnt++] = data;
    if(byteCnt == msgLength)     
      call PhyPacketRx.recvFooter();
  }
}
