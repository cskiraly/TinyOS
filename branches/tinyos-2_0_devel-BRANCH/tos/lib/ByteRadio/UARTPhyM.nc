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
 * - Description ---------------------------------------------------------
 *
 * - Revision -------------------------------------------------------------
 * $Revision: 1.1.2.2 $
 * $Date: 2005-07-04 00:39:37 $
 * @author: Kevin Klues (klues@tkn.tu-berlin.de)
 * ========================================================================
 */
 
#include "crc.h"

module UARTPhyM {
   provides {
      interface Init;
      interface PhyPacketTx;
			interface RadioByteComm as SerializerRadioByteComm;
			interface PhyPacketRx;
   }
   uses {
      interface RadioByteComm;
   }
}
implementation
{
   /**************** Module Definitions  *****************/
   typedef enum {
	    STATE_NULL,
      STATE_PREAMBLE,    
      STATE_SYNC,
			STATE_SFD,
			STATE_LENGTH,
			STATE_HEADER_DONE,
			STATE_DATA,
      STATE_CRC1,
      STATE_CRC2,
			STATE_FOOTER_DONE,
      STATE_CANCEL_HEADER,
      STATE_CANCEL_DATA,
      STATE_CANCEL_FOOTER
   } phyState_t;
   
#define PREAMBLE_BYTE     0x55
#define SYNC_BYTE         0xFF
#define SFD_BYTE          0x33   
   
   /**************** Module Global Variables  *****************/
   phyState_t phyState;   // Current Phy state State
   uint16_t numPreambles;  //Number of preambles to send before the packet
   uint16_t crc;           //CRC value of either the current incoming or outgoing packet
	 uint16_t length;       //Length of the payload to be sent by PacketSerializerM

   /**************** Local Function Declarations  *****************/
   void TransmitNextByte();
   void ReceiveNextByte(uint8_t data);

   /**************** Radio Init  *****************/
   command error_t Init.init(){
     atomic {
       phyState = STATE_NULL;
       numPreambles = 1;  
       crc = 0;
     }     
     return SUCCESS;
   }  
   
   async command void PhyPacketTx.sendHeader(uint8_t length_value) {
     atomic {
       phyState = STATE_PREAMBLE;
       length = length_value;
       crc = 0;
     }     
     TransmitNextByte();
   }
   
   async command void SerializerRadioByteComm.txByte(uint8_t data) {
     atomic crc = crcByte(crc, data);
     call RadioByteComm.txByte(data);
   }
   
   async command bool SerializerRadioByteComm.isTxDone() {
     return call RadioByteComm.isTxDone();
   }   
   
   async command void PhyPacketTx.sendFooter() {
     atomic phyState = STATE_CRC1;
     TransmitNextByte();
   }      
   

   /**************** Radio Recv ****************/
   async command void PhyPacketRx.recvHeader() {
     atomic phyState = STATE_PREAMBLE;
   }
   
   async command void PhyPacketRx.recvFooter() {
     atomic phyState = STATE_CRC1;
   }      
   
	 async command error_t PhyPacketTx.cancel() {
       switch(phyState) {
         case STATE_PREAMBLE:    
         case STATE_SYNC:
         case STATE_SFD:
         case STATE_LENGTH:
         case STATE_HEADER_DONE:
            atomic phyState = STATE_CANCEL_HEADER;
            return SUCCESS;
         case STATE_DATA:
            atomic phyState = STATE_CANCEL_DATA;
            return SUCCESS;           
         case STATE_CRC1:
         case STATE_CRC2:
            atomic phyState = STATE_CANCEL_FOOTER;
            return SUCCESS;
         default:
           return FAIL;
       }   
	 }
	 
   /**************** Tx Done ****************/
   async event void RadioByteComm.txByteReady(error_t error) {
     if(error == SUCCESS) {
			 TransmitNextByte();
		 }
     else {
       switch(phyState) {
         case STATE_PREAMBLE:    
         case STATE_SYNC:
         case STATE_SFD:
         case STATE_LENGTH:
            signal PhyPacketTx.sendHeaderDone(error);
            break;
         case STATE_DATA:
         case STATE_CRC1:
         case STATE_CRC2:
            signal PhyPacketTx.sendFooterDone(error);
            break;
         default:
           signal SerializerRadioByteComm.txByteReady(error);
           break;
       }
     }
   }	 
	 
   void TransmitNextByte() {
    switch(phyState) {   
       case STATE_PREAMBLE:
         atomic {
           if(numPreambles > 0)
             numPreambles--;
           else phyState = STATE_SYNC;            
         }
         call RadioByteComm.txByte(PREAMBLE_BYTE);
				 break;
       case STATE_SYNC:
         atomic phyState = STATE_SFD;
         call RadioByteComm.txByte(SYNC_BYTE);
				 break;
       case STATE_SFD:
         atomic phyState = STATE_HEADER_DONE;
         call RadioByteComm.txByte(SFD_BYTE);
				 break;
       case STATE_LENGTH:
         atomic {
				   phyState = STATE_HEADER_DONE;
				   crc = crcByte(crc, length);
				 }
         call RadioByteComm.txByte(length);
				 break;				 
       case STATE_HEADER_DONE:
			 	 atomic phyState = STATE_DATA;
         signal PhyPacketTx.sendHeaderDone(SUCCESS);  
				 break;
       case STATE_DATA:
         signal SerializerRadioByteComm.txByteReady(SUCCESS);  
				 break;				 
       case STATE_CRC1:		 
			 	 atomic phyState = STATE_CRC2;
         call RadioByteComm.txByte((uint8_t)(crc >> 8));
         break;
       case STATE_CRC2: 
			 	 atomic phyState = STATE_FOOTER_DONE;	
				 call RadioByteComm.txByte((uint8_t)(crc));					
				 break;
       case STATE_FOOTER_DONE:
         atomic phyState = STATE_NULL;		
				 while(call RadioByteComm.isTxDone() == FALSE); 
         signal PhyPacketTx.sendFooterDone(SUCCESS); 	
				 break;
       case STATE_CANCEL_HEADER:
         atomic phyState = STATE_NULL;		
         signal PhyPacketTx.sendHeaderDone(ECANCEL); 	
				 break;			
       case STATE_CANCEL_DATA:
         atomic phyState = STATE_NULL;		
         signal SerializerRadioByteComm.txByteReady(ECANCEL);		
				 break;			
       case STATE_CANCEL_FOOTER:
         atomic phyState = STATE_NULL;		
         signal PhyPacketTx.sendFooterDone(ECANCEL); 							 				 				 			  
       default:
         break;                     
	   }
   }
   
   /**************** Rx Done ****************/
   async event void RadioByteComm.rxByteReady(uint8_t data) {
      ReceiveNextByte(data);
   }
  
  /* Receive the next Byte from the USART */
  void ReceiveNextByte(uint8_t data) {
    switch(phyState) {
      case STATE_PREAMBLE:
       if(data == PREAMBLE_BYTE)
         atomic phyState = STATE_SYNC;
      case STATE_SYNC:
        if(data != PREAMBLE_BYTE) {
           if (data == SFD_BYTE) {
             atomic phyState = STATE_LENGTH;
           }
           else atomic phyState = STATE_SFD;
        }
        break;
      case STATE_SFD:         
        if (data == SFD_BYTE)
           atomic phyState = STATE_LENGTH;
        else atomic phyState = STATE_PREAMBLE;
        break;				
      case STATE_LENGTH:
			  atomic {
				  phyState = STATE_DATA;
			    crc = crcByte(crc, data);
				}
        signal PhyPacketRx.recvHeaderDone(data);
        break;
      case STATE_DATA:
			   atomic crc = crcByte(crc, data);
         signal SerializerRadioByteComm.rxByteReady(data);  
				 break;							
      case STATE_CRC1:
        if (data == (uint8_t)(crc >> 8))
          atomic phyState = STATE_CRC2;
        else {
          atomic phyState = STATE_NULL;
          signal PhyPacketRx.recvFooterDone(FALSE);
        }
        break;				
      case STATE_CRC2:
        atomic phyState = STATE_NULL;
        if (data == (uint8_t)(crc))
          signal PhyPacketRx.recvFooterDone(TRUE);
        else
          signal PhyPacketRx.recvFooterDone(TRUE);
        break;
      default:
        break;
    }
	}
}
