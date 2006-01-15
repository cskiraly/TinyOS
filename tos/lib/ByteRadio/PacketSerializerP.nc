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
* $Revision: 1.1.2.5 $
* $Date: 2006-01-15 22:31:32 $
* ========================================================================
*/

#include "crc.h"

//!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
// dirty hack for now
#include <message.h>

/**
* PacketSerializerP module
*
* @author Kevin Klues <klues@tkn.tu-berlin.de>
* @author Philipp Huppertz <huppertz@tkn.tu-berlin.de>
*/  

module PacketSerializerP {
provides {
	interface Init;
	interface Send;
	interface Receive;
	interface Packet;
	interface PacketAcknowledgements;
	
}
uses {
	interface RadioByteComm;
	interface PhyPacketTx;
	interface PhyPacketRx;
}
}
implementation {
	/**************** Module Global Variables  *****************/
	typedef enum {
                STATE_CRC1,
		STATE_CRC2,
		STATE_CRC_DONE,
	} crcState_t;

	uint8_t *txBufPtr;    // pointer to tx buffer
	uint8_t *rxBufPtr;    // pointer to rx buffer
	message_t rxMsg;      // rx message buffer
	uint16_t byteCnt;     // index into current datapacket
	uint16_t crc;         // CRC value of either the current incoming or outgoing packet
	crcState_t crcState;  // CRC state

	/**************** Local Function Declarations  *****************/
	void TransmitNextByte();
	void ReceiveNextByte(uint8_t data);

	// platform-independant radiostructures are called message_radio_header_t & message_radio_footer_t
	/**************** Packet structure accessor functions************/
	message_radio_header_t* getHeader(message_t* amsg) {
		return (message_radio_header_t*)(amsg->data - sizeof(message_radio_header_t));
	}

	message_radio_footer_t* getFooter(message_t* amsg) {
		return (message_radio_footer_t*)(amsg->footer);
	}

 message_radio_metadata_t* getMetadata(message_t* amsg) {
   return (message_radio_metadata_t*)((uint8_t*)amsg->footer + sizeof(message_radio_footer_t));
	}

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
		message_radio_header_t* header = getHeader((message_t*)(&rxMsg));
		signal Receive.receive((message_t*)rxBufPtr, ((message_t*)rxBufPtr)->data, header->length);
		call PhyPacketRx.recvHeader();
	}   

	/**************** Radio Init  *****************/
	command error_t Init.init(){
		atomic {
			crc = 0;
			txBufPtr = NULL;
			rxBufPtr = (uint8_t*)(&rxMsg);
			byteCnt = 0;
		}     
		return SUCCESS;
	}

	/**************** Radio Send ****************/
	command error_t Send.send(message_t* msg, uint8_t len) {
		message_radio_header_t* header = getHeader(msg);
		atomic {
			crc = 0;
			txBufPtr = (uint8_t*) msg;
			header->length = len;
			// message_header_t can contain more than only the message_radio_header_t 
			// (see /tos/platforms/mica2/RadioTOSMsg.h should be PlatformTOSMsg.h or something)
			byteCnt = (sizeof(message_header_t) - sizeof(message_radio_header_t)); // offset
		}
		call PhyPacketTx.sendHeader();	
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

	async event void RadioByteComm.txByteReady(error_t error) {
		if(error == SUCCESS)
			TransmitNextByte();
		else if(error == ECANCEL)
			post SendDoneCancelTask();
		else post SendDoneFailTask();
	}   

	void TransmitNextByte() {
   message_radio_header_t* header = getHeader((message_t*) txBufPtr);
  if (byteCnt < header->length + sizeof(message_header_t) ) {  // send (data + header), compute crc
			atomic {
				crcState = STATE_CRC1;
				crc = crcByte(crc, txBufPtr[byteCnt]);
			}
			call RadioByteComm.txByte(txBufPtr[byteCnt++]);
		} else {  // send crc
			switch(crcState) {   
				case STATE_CRC1:
					atomic crcState = STATE_CRC2;
					call RadioByteComm.txByte((uint8_t)(crc >> 8));
					break;
				case STATE_CRC2:
					atomic crcState = STATE_CRC_DONE;
					call RadioByteComm.txByte((uint8_t)(crc));
					break;
				case STATE_CRC_DONE:
					call PhyPacketTx.sendFooter();	// no footer @ this time
					break;
				default:
					break;
			}
		}
	}   

	async event void PhyPacketTx.sendFooterDone(error_t error) {
		if(error == SUCCESS)
			post SendDoneSuccessTask();
		else if(error == ECANCEL)
			post SendDoneCancelTask();        
		else post SendDoneFailTask();
	}


	/**************** Radio Receive ****************/
	async event void PhyPacketRx.recvHeaderDone() {
   byteCnt = (sizeof(message_header_t) - sizeof(message_radio_header_t)); 
   getHeader(&rxMsg)->length = sizeof(message_radio_header_t);
	}  

	async event void RadioByteComm.rxByteReady(uint8_t data) {
		ReceiveNextByte(data);
	}   

	async event void PhyPacketRx.recvFooterDone(bool error) {
		post ReceiveTask();
	}   

	/* Receive the next Byte from the USART */
	void ReceiveNextByte(uint8_t data) { //ReceiveNextPayload
		rxBufPtr[byteCnt++] = data;
  if ( byteCnt < (getHeader(&rxMsg)->length + sizeof(message_radio_header_t)) ) {
			crc = crcByte(crc, data);
  } else if ( byteCnt == (getHeader(&rxMsg)->length + sizeof(message_radio_header_t) + sizeof(message_radio_footer_t)) ) {
			message_radio_footer_t* footer = getFooter((message_t*)rxBufPtr);
			// we don't care about wrong crc in this layer
			footer->crc = (footer->crc == crc);
			call PhyPacketRx.recvFooter();
		}
	}
	
	
	/**************** Packet interface ****************/

	command void Packet.clear(message_t* msg) {
		memset(msg, 0, sizeof(message_t));
	}

	command uint8_t Packet.payloadLength(message_t* msg) {
		return (getHeader(msg))->length;
	}

	command uint8_t Packet.maxPayloadLength() {
		return TOSH_DATA_LENGTH;
	}

	command void* Packet.getPayload(message_t* msg, uint8_t* len) {
		if (len != NULL) {
			*len = (getHeader(msg))->length;
		}
		return (void*)msg->data;
	}

	
	/**************** PacketAcknowledgements interface ****************/

	async command error_t PacketAcknowledgements.requestAck(message_t* msg) {
		return FAIL;
	}

	async command error_t PacketAcknowledgements.noAck(message_t* msg) {
		return SUCCESS;
	}

	async command bool PacketAcknowledgements.wasAcked(message_t* msg) {
		return FALSE;
	}
	
	
}
