// $Id: SerialM.nc,v 1.1.2.1 2005-04-18 17:56:32 gtolle Exp $

/* -*- Mode: C; c-basic-indent: 2; indent-tabs-mode: nil -*- */ 
/*									
 *  IMPORTANT: READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.  By
 *  downloading, copying, installing or using the software you agree to
 *  this license.  If you do not agree to this license, do not download,
 *  install, copy or use the software.
 *
 *  Intel Open Source License 
 *
 *  Copyright (c) 2002 Intel Corporation 
 *  All rights reserved. 
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions are
 *  met:
 * 
 *	Redistributions of source code must retain the above copyright
 *  notice, this list of conditions and the following disclaimer.
 *	Redistributions in binary form must reproduce the above copyright
 *  notice, this list of conditions and the following disclaimer in the
 *  documentation and/or other materials provided with the distribution.
 *      Neither the name of the Intel Corporation nor the names of its
 *  contributors may be used to endorse or promote products derived from
 *  this software without specific prior written permission.
 *  
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 *  ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 *  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 *  PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE INTEL OR ITS
 *  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 *  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 *  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 *  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 *  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 *  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 *  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * Author: Phil Buonadonna
 * Revision: $Revision: 1.1.2.1 $
 * 
 */

/*
 * FramerM
 * 
 * This modules provides framing for TOS_Msg's using PPP-HDLC-like framing 
 * (see RFC 1662).  When sending, a TOS_Msg is encapsulated in an HLDC frame.
 * Receiving is similar EXCEPT that the component expects a special token byte
 * be received before the data payload. The purpose of the token is to feed back
 * an acknowledgement to the sender which serves as a crude form of flow-control.
 * This module is intended for use with the Packetizer class found in
 * tools/java/net/packet/Packetizer.java.
 * 
 */

/**
 * @author Phil Buonadonna
 * @author Gilman Tolle
 */

module SerialM {

  provides {
    interface Init;
    interface Receive;
    interface Send;
  }

  uses {
    interface Leds;
    interface HPLUART as SerialByteComm;
    interface TaskBasic as PacketRcvd;
    interface TaskBasic as PacketSent;
  }
}

implementation {

  enum {
    HDLC_QUEUESIZE	   = 2,
    HDLC_MTU		   = 36,
    HDLC_FCS_SIZE          = 2,
    HDLC_FLAG_BYTE	   = 0x7e,
    HDLC_CTLESC_BYTE	   = 0x7d,
    PROTO_ACK              = 64,
    PROTO_PACKET_ACK       = 65,
    PROTO_PACKET_NOACK     = 66,
    PROTO_UNKNOWN          = 255
  };

  enum {
    RXSTATE_NOSYNC,
    RXSTATE_PROTO,
    RXSTATE_TOKEN,
    RXSTATE_INFO,
    RXSTATE_ESC
  };

  enum {
    TXSTATE_IDLE,
    TXSTATE_PROTO,
    TXSTATE_INFO,
    TXSTATE_ESC,
    TXSTATE_FCS1,
    TXSTATE_FCS2,
    TXSTATE_ENDFLAG,
    TXSTATE_FINISH,
    TXSTATE_ERROR
  };

  enum {
    FLAGS_TOKENPEND = 0x2,
    FLAGS_DATAPEND  = 0x4,
    FLAGS_UNKNOWN   = 0x8
  };

  message_t gMsgRcvBuf[HDLC_QUEUESIZE];

  typedef struct _MsgRcvEntry {
    uint16_t Length;	// Does not include 'Proto' or 'Token' fields
    uint8_t Proto;
    uint8_t Token;	// Used for sending acknowledgements
    message_t* pMsg;
  } MsgRcvEntry_t ;

  MsgRcvEntry_t gMsgRcvTbl[HDLC_QUEUESIZE];

  uint8_t* gpRxBuf;    
  uint8_t* gpTxBuf;

  uint8_t  gFlags;

  // Flags variable protects atomicity
  norace uint8_t  gTxState;
  norace uint8_t  gPrevTxState;
  norace uint16_t  gTxProto;
  norace uint16_t gTxByteCnt;
  norace uint16_t gTxLength;
  norace uint16_t gTxRunningCRC;


  uint8_t  gRxState;
  uint8_t  gRxHeadIndex;
  uint8_t  gRxTailIndex;
  uint16_t gRxByteCnt;
  
  uint16_t gRxRunningCRC;
  
  message_t* gpTxMsg;
  uint8_t gTxTokenBuf;
  uint8_t gTxUnknownBuf;
  norace uint8_t gTxEscByte;

  /* PROTOTYPES */
  void HDLCInitialize();
  uint16_t crcByte(uint16_t crc, uint8_t b);

  error_t StartTx();
  error_t TxArbitraryByte(uint8_t inByte);

  command error_t Init.init() {
    HDLCInitialize();
    call SerialByteComm.init();
    return SUCCESS;
  }

  void HDLCInitialize() {
    int i;
    atomic {
      for (i = 0;i < HDLC_QUEUESIZE; i++) {
        gMsgRcvTbl[i].pMsg = &gMsgRcvBuf[i];
        gMsgRcvTbl[i].Length = 0;
        gMsgRcvTbl[i].Token = 0;
      }
      gTxState = TXSTATE_IDLE;
      gTxByteCnt = 0;
      gTxLength = 0;
      gTxRunningCRC = 0;
      gpTxMsg = NULL;
      
      gRxState = RXSTATE_NOSYNC;
      gRxHeadIndex = 0;
      gRxTailIndex = 0;
      gRxByteCnt = 0;
      gRxRunningCRC = 0;
      gpRxBuf = (uint8_t *)gMsgRcvTbl[gRxHeadIndex].pMsg;
    }
  }

  async event error_t SerialByteComm.get(uint8_t data) {

    switch (gRxState) {

    case RXSTATE_NOSYNC: 

//      call Leds.led1Toggle();

      if ((data == HDLC_FLAG_BYTE) && 
	  (gMsgRcvTbl[gRxHeadIndex].Length == 0)) {
        gMsgRcvTbl[gRxHeadIndex].Token = 0;
	gRxByteCnt = gRxRunningCRC = 0;
        gpRxBuf = (uint8_t *)gMsgRcvTbl[gRxHeadIndex].pMsg;
    	gRxState = RXSTATE_PROTO;
      }

      break;
      
    case RXSTATE_PROTO:

      if (data == HDLC_FLAG_BYTE) {
        break;
      }
      gMsgRcvTbl[gRxHeadIndex].Proto = data;
      gRxRunningCRC = crcByte(gRxRunningCRC,data);
      switch (data) {
      case PROTO_PACKET_ACK:
	gRxState = RXSTATE_TOKEN;
	break;
      case PROTO_PACKET_NOACK:
	gRxState = RXSTATE_INFO;
	break;
      default:  // PROTO_ACK packets are not handled
	gRxState = RXSTATE_NOSYNC;
	break;
      }

      break;

    case RXSTATE_TOKEN:

      if (data == HDLC_FLAG_BYTE) {
        gRxState = RXSTATE_NOSYNC;
      }
      else if (data == HDLC_CTLESC_BYTE) {
        gMsgRcvTbl[gRxHeadIndex].Token = 0x20;
      }
      else {
        gMsgRcvTbl[gRxHeadIndex].Token ^= data;
        gRxRunningCRC = crcByte(gRxRunningCRC,gMsgRcvTbl[gRxHeadIndex].Token);
        gRxState = RXSTATE_INFO;
      }

      break;

    case RXSTATE_INFO:

      if (gRxByteCnt > HDLC_MTU) {
	gRxByteCnt = gRxRunningCRC = 0;
	gMsgRcvTbl[gRxHeadIndex].Length = 0;
	gMsgRcvTbl[gRxHeadIndex].Token = 0;
	gRxState = RXSTATE_NOSYNC;
      }
      else if (data == HDLC_CTLESC_BYTE) {
	gRxState = RXSTATE_ESC;
      }
      else if (data == HDLC_FLAG_BYTE) {
	if (gRxByteCnt >= 2) {
	  uint16_t usRcvdCRC = (gpRxBuf[(gRxByteCnt-1)] & 0xff);
	  usRcvdCRC = (usRcvdCRC << 8) | (gpRxBuf[(gRxByteCnt-2)] & 0xff);
	  if (usRcvdCRC == gRxRunningCRC) {
	    gMsgRcvTbl[gRxHeadIndex].Length = gRxByteCnt - 2;

	    call PacketRcvd.postTask();
	    if (++gRxHeadIndex >= HDLC_QUEUESIZE) gRxHeadIndex = 0;

	    // what the task does
/*
	    call Leds.led0Toggle();
	    gMsgRcvTbl[gRxHeadIndex].Length = 0;
	    gMsgRcvTbl[gRxHeadIndex].Token = 0;
	    if (++gRxTailIndex >= HDLC_QUEUESIZE) gRxTailIndex = 0;
*/

          } else {
	    gMsgRcvTbl[gRxHeadIndex].Length = 0;
	    gMsgRcvTbl[gRxHeadIndex].Token = 0;
          }
	  if (gMsgRcvTbl[gRxHeadIndex].Length == 0) {
	    gpRxBuf = (uint8_t *)gMsgRcvTbl[gRxHeadIndex].pMsg;
	    gRxState = RXSTATE_PROTO;
	  }
	  else {
	    gRxState = RXSTATE_NOSYNC;
	  }
	} else {
	  gMsgRcvTbl[gRxHeadIndex].Length = 0;
	  gMsgRcvTbl[gRxHeadIndex].Token = 0;
	  gRxState = RXSTATE_NOSYNC;
	}
	gRxByteCnt = gRxRunningCRC = 0;
      }
      else {
	gpRxBuf[gRxByteCnt] = data;
	if (gRxByteCnt >= 2) {
	  gRxRunningCRC = crcByte(gRxRunningCRC,gpRxBuf[(gRxByteCnt-2)]);
	}
	gRxByteCnt++;
      }

      break;

    case RXSTATE_ESC:

      if (data == HDLC_FLAG_BYTE) {
	// Error case, fail and resync
	gRxByteCnt = gRxRunningCRC = 0;
	gMsgRcvTbl[gRxHeadIndex].Length = 0;
	gMsgRcvTbl[gRxHeadIndex].Token = 0;
	gRxState = RXSTATE_NOSYNC;
      }
      else {
	data = data ^ 0x20;
        gpRxBuf[gRxByteCnt] = data;
	if (gRxByteCnt >= 2) {
	  gRxRunningCRC = crcByte(gRxRunningCRC,gpRxBuf[(gRxByteCnt-2)]);
	}
	gRxByteCnt++;
	gRxState = RXSTATE_INFO;
      }

      break;

    default:
      gRxState = RXSTATE_NOSYNC;
      break;
    }

    return SUCCESS;
  }

  event void PacketRcvd.runTask() {
    MsgRcvEntry_t *pRcv = &gMsgRcvTbl[gRxTailIndex];
    message_t* pBuf = pRcv->pMsg;
    error_t Result = SUCCESS;

    call Leds.led1Toggle();

    if (pRcv->Proto == PROTO_PACKET_ACK) {

      atomic {
	if (!(gFlags & FLAGS_TOKENPEND)) {
	  gFlags |= FLAGS_TOKENPEND;
	  gTxTokenBuf = pRcv->Token;
	}
	else {
	  Result = FAIL;
	}
      }
    }

    if (pRcv->Length >= offsetof(message_t,data)) {
      pBuf = signal Receive.receive(pBuf, pBuf, pRcv->Length);
    }
    
    atomic {
      if (pBuf) {
	pRcv->pMsg = pBuf;
      }
      pRcv->Length = 0; 
      pRcv->Token = 0; 
    }
    if (++gRxTailIndex >= HDLC_QUEUESIZE) gRxTailIndex = 0;

    if (Result == SUCCESS) {
      Result = StartTx();
    }
  }

  command error_t Send.send(message_t* msg, uint8_t len) {

    error_t result = SUCCESS;

    msg->length = len;

    atomic {
      if (!(gFlags & FLAGS_DATAPEND)) {
       gFlags |= FLAGS_DATAPEND; 
       gpTxMsg = msg;
      }
      else {
        result = FAIL;
      }
    }

    if (result == SUCCESS) {
      result = StartTx();
    }

    return result;
  }

  error_t StartTx() {
    error_t result = SUCCESS;
    bool fInitiate = FALSE;

    atomic {
      if (gTxState == TXSTATE_IDLE) {
        if (gFlags & FLAGS_TOKENPEND) {
          gpTxBuf = (uint8_t *)&gTxTokenBuf;
          gTxProto = PROTO_ACK;
          gTxLength = sizeof(gTxTokenBuf);
          fInitiate = TRUE;
          gTxState = TXSTATE_PROTO;
        }
        else if (gFlags & FLAGS_DATAPEND) {
          gpTxBuf = (uint8_t *)gpTxMsg;
          gTxProto = PROTO_PACKET_NOACK;
          gTxLength = gpTxMsg->length;
          fInitiate = TRUE;
          gTxState = TXSTATE_PROTO;
        }
        else if (gFlags & FLAGS_UNKNOWN) {
          gpTxBuf = (uint8_t *)&gTxUnknownBuf;
          gTxProto = PROTO_UNKNOWN;
          gTxLength = sizeof(gTxUnknownBuf);
          fInitiate = TRUE;
          gTxState = TXSTATE_PROTO;
        }
      }
    }
    
    if (fInitiate) {
      atomic {
        gTxRunningCRC = 0; gTxByteCnt = 0;
      }
      result = call SerialByteComm.put(HDLC_FLAG_BYTE);
      if (result != SUCCESS) {
        atomic gTxState = TXSTATE_ERROR;
        call PacketSent.postTask();
      }
    }
    
    return result;
  }    

  async event error_t SerialByteComm.putDone() {
    error_t TxResult = SUCCESS;
    uint8_t nextByte;

    if (gTxState == TXSTATE_FINISH) {
      gTxState = TXSTATE_IDLE;
      call PacketSent.postTask();
      return SUCCESS;
    }
    
    switch (gTxState) {

    case TXSTATE_PROTO:
      gTxState = TXSTATE_INFO;
      gTxRunningCRC = crcByte(gTxRunningCRC,(uint8_t)(gTxProto & 0x0FF));
      TxResult = call SerialByteComm.put((uint8_t)(gTxProto & 0x0FF));
      break;
      
    case TXSTATE_INFO:
      nextByte = gpTxBuf[gTxByteCnt];
      
      gTxRunningCRC = crcByte(gTxRunningCRC,nextByte);
      gTxByteCnt++;
      if (gTxByteCnt >= gTxLength) {
	gTxState = TXSTATE_FCS1;
      }
      
      TxResult = TxArbitraryByte(nextByte);
      break;
      
    case TXSTATE_ESC:

      TxResult = call SerialByteComm.put((gTxEscByte ^ 0x20));
      gTxState = gPrevTxState;
      break;
	
    case TXSTATE_FCS1:
      nextByte = (uint8_t)(gTxRunningCRC & 0xff); // LSB
      gTxState = TXSTATE_FCS2;
      TxResult = TxArbitraryByte(nextByte);
      break;

    case TXSTATE_FCS2:
      nextByte = (uint8_t)((gTxRunningCRC >> 8) & 0xff); // MSB
      gTxState = TXSTATE_ENDFLAG;
      TxResult = TxArbitraryByte(nextByte);
      break;

    case TXSTATE_ENDFLAG:
      gTxState = TXSTATE_FINISH;
      TxResult = call SerialByteComm.put(HDLC_FLAG_BYTE);

      break;

    case TXSTATE_FINISH:
    case TXSTATE_ERROR:

    default:
      break;

    }

    if (TxResult != SUCCESS) {
      gTxState = TXSTATE_ERROR;
      call PacketSent.postTask();
    }

    return SUCCESS;
  }

  error_t TxArbitraryByte(uint8_t inByte) {
    if ((inByte == HDLC_FLAG_BYTE) || (inByte == HDLC_CTLESC_BYTE)) {
      atomic {
        gPrevTxState = gTxState;
        gTxState = TXSTATE_ESC;
        gTxEscByte = inByte;
      }
      inByte = HDLC_CTLESC_BYTE;
    }
    
    return call SerialByteComm.put(inByte);
  }

  event void PacketSent.runTask() {
    error_t TxResult = SUCCESS;

    atomic {
      if (gTxState == TXSTATE_ERROR) {
	TxResult = FAIL;
        gTxState = TXSTATE_IDLE;
      }
    }
    if (gTxProto == PROTO_ACK) {
      atomic gFlags ^= FLAGS_TOKENPEND;
    }
    else{
      atomic gFlags ^= FLAGS_DATAPEND;
      signal Send.sendDone((message_t*)gpTxMsg,TxResult);
      atomic gpTxMsg = NULL;
    }

    // Trigger transmission in case something else is pending
    StartTx();
  }

  /**
   * Default CRC function. Note that avrmote has a much more efficient one. 
   *
   * This CRC-16 function produces a 16-bit running CRC that adheres to the
   * ITU-T CRC standard.
   *
   * The ITU-T polynomial is: G_16(x) = x^16 + x^12 + x^5 + 1
   *
   */
  
  uint16_t crcByte(uint16_t crc, uint8_t b) {
    uint8_t i;
    
    crc = crc ^ b << 8;
    i = 8;
    do
      if (crc & 0x8000)
	crc = crc << 1 ^ 0x1021;
      else
	crc = crc << 1;
    while (--i);
    
    return crc;
  }

  default event message_t* Receive.receive(message_t* msg, 
					   void* payload, 
					   uint8_t len) {
    return msg;
  }

  command error_t Send.cancel(message_t* msg) {
    return FAIL;
  }
  
  default event void Send.sendDone(message_t* msg, 
				   error_t error) {

  }
}
