// $Id: SerialP.nc,v 1.1.2.4 2006-01-11 17:52:57 bengreenstein Exp $
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
 * Revision: $Revision: 1.1.2.4 $
 * 
 */

/*
 * 
 * This modules provides framing for TOS_Msgs using PPP-HDLC-like
 * framing (see RFC 1662).  When sending, a TOS_Msg is encapsulated in
 * an HDLC frame.  Receiving is similar EXCEPT that the component
 * expects a special token byte be received before the data
 * payload. The purpose of the token is to feed back an
 * acknowledgement to the sender which serves as a crude form of
 * flow-control.
 *
 * @author Phil Buonadonna
 * @author Lewis Girod
 * @author Ben Greenstein
 * @date   August 7 2005
 */


includes AM;
includes crc;

module SerialP {

  provides {
    interface Init;
    interface SplitControl;
    interface SendBytePacket;
    interface ReceiveBytePacket;
  }

  uses {
    interface SerialFrameComm;
    interface Leds;
    interface StdControl as SerialControl;
  }
}
implementation {
#define NO_TX_SEQNO

  enum {
    RX_DATA_BUFFER_SIZE = 2,
    TX_DATA_BUFFER_SIZE = 4,
    SERIAL_MTU = 255,
    SERIAL_VERSION = 1,
    ACK_QUEUE_SIZE = 5,
  };

  enum {
    RXSTATE_NOSYNC,
    RXSTATE_PROTO,
    RXSTATE_TOKEN,
    RXSTATE_INFO,
    RXSTATE_INACTIVE
  };

  enum {
    TXSTATE_IDLE,
    TXSTATE_PROTO,
    TXSTATE_SEQNO,
    TXSTATE_INFO,
    TXSTATE_FCS1,
    TXSTATE_FCS2,
    TXSTATE_ENDFLAG,
    TXSTATE_ENDWAIT,
    TXSTATE_FINISH,
    TXSTATE_ERROR,
    TXSTATE_INACTIVE
  };

  typedef enum {
    BUFFER_AVAILABLE,
    BUFFER_FILLING,
    BUFFER_COMPLETE,
  } tx_data_buffer_states_t;

  enum {
    TX_ACK_INDEX = 0,
    TX_DATA_INDEX = 1,
    TX_BUFFER_COUNT = 2,
  };


  typedef struct {
    uint8_t writePtr;
    uint8_t readPtr;
    uint8_t buf[RX_DATA_BUFFER_SIZE+1]; // one wasted byte: writePtr == readPtr means empty
  } rx_buf_t;

  typedef struct {
    uint8_t state;
    uint8_t buf;    
  } tx_buf_t;
  
  typedef struct {
    uint8_t writePtr;
    uint8_t readPtr;
    uint8_t buf[ACK_QUEUE_SIZE+1]; // one wasted byte: writePtr == readPtr means empty    
  } ack_queue_t;

  /* Buffers */

  rx_buf_t RxBuf;
  tx_buf_t TxBuf[TX_BUFFER_COUNT];

  /* Receive State */

  uint8_t  RxState;
  uint8_t  RxByteCnt;
  uint8_t  RxProto;
  uint8_t  RxSeqno;
  uint16_t RxCRC;

  /* Transmit State */

  norace uint8_t  TxState;
  norace uint8_t  TxByteCnt;
  norace uint8_t  TxProto;
  norace uint8_t  TxSeqno;
  norace uint16_t TxCRC;
  uint8_t  TxPending;
  norace uint8_t TxIndex;
  
  /* Ack Queue */
  ack_queue_t AckQ;

  /* stats */
  radio_stats_t stats;

  bool offPending = FALSE;

  // Prototypes

  inline void txInit();
  inline void rxInit();
  inline void ackInit();
  inline void statsInit();

  inline bool ack_queue_is_full(); 
  inline bool ack_queue_is_empty(); 
  inline void ack_queue_push(uint8_t token);
  inline uint8_t ack_queue_top();
  uint8_t ack_queue_pop();

  inline void rx_buffer_init();
  inline bool rx_buffer_is_full();
  inline bool rx_buffer_is_empty();
  inline void rx_buffer_push(uint8_t data);
  inline uint8_t rx_buffer_top();
  inline uint8_t rx_buffer_pop();
  inline uint16_t rx_current_crc();

  void rx_state_machine(bool isDelimeter, uint8_t data);
  void MaybeScheduleTx();
  task void RunTx();
  


  inline void txInit(){
    uint8_t i;
    atomic for (i = 0; i < TX_BUFFER_COUNT; i++) TxBuf[i].state = BUFFER_AVAILABLE;
    TxState = TXSTATE_IDLE;
    TxByteCnt = 0;
    TxProto = 0;
    TxSeqno = 0;
    TxCRC = 0; 
    TxPending = FALSE;
    TxIndex = 0;
  }

  inline void rxInit(){
    RxBuf.writePtr = RxBuf.readPtr = 0;
    RxState = RXSTATE_NOSYNC;
    RxByteCnt = 0;
    RxProto = 0;
    RxSeqno = 0;
    RxCRC = 0;
  }

  inline void ackInit(){
    AckQ.writePtr = AckQ.readPtr = 0;
  }

  inline void statsInit(){
    memset(&stats, 0, sizeof(stats));
    stats.platform = 0; // TODO: set platform
    stats.MTU = SERIAL_MTU;
    stats.version = SERIAL_VERSION;
  }
  
  command error_t Init.init() {

    txInit();
    rxInit();
    ackInit();
    statsInit();

    return SUCCESS;
  }


  /*
   *  buffer and queue manipulation
   */

  inline bool ack_queue_is_full(){ 
    uint8_t tmp, tmp2;
    atomic {
      tmp = AckQ.writePtr;
      tmp2 = AckQ.readPtr;
    }
    if (++tmp > ACK_QUEUE_SIZE) tmp = 0;
    return (tmp == tmp2);
  }

  inline bool ack_queue_is_empty(){
    bool ret;
    atomic ret = (AckQ.writePtr == AckQ.readPtr); 
    return ret;
  }

  inline void ack_queue_push(uint8_t token) {
    if (!ack_queue_is_full()){
      atomic {
        AckQ.buf[AckQ.writePtr] = token;
        if (++AckQ.writePtr > ACK_QUEUE_SIZE) AckQ.writePtr = 0;
      }
      MaybeScheduleTx();
    }
  }

  inline uint8_t ack_queue_top() {
    uint8_t tmp = 0;
    atomic {
      if (!ack_queue_is_empty()){
        tmp =  AckQ.buf[AckQ.readPtr];
      }
    }
    return tmp;
  }

  uint8_t ack_queue_pop() {
    uint8_t retval = 0;
    atomic {
      if (AckQ.writePtr != AckQ.readPtr){
        retval =  AckQ.buf[AckQ.readPtr];
        if (++(AckQ.readPtr) > ACK_QUEUE_SIZE) AckQ.readPtr = 0;
      }
    }
    return retval;
  }


  /* 
   * Buffer Manipulation
   */

  inline void rx_buffer_init(){
    RxBuf.writePtr = RxBuf.readPtr = 0;
  }
  inline bool rx_buffer_is_full() {
    uint8_t tmp = RxBuf.writePtr;
    if (++tmp > RX_DATA_BUFFER_SIZE) tmp = 0;
    return (tmp == RxBuf.readPtr);
  }
  inline bool rx_buffer_is_empty(){
    return (RxBuf.readPtr == RxBuf.writePtr);
  }
  inline void rx_buffer_push(uint8_t data){
    RxBuf.buf[RxBuf.writePtr] = data;
    if (++(RxBuf.writePtr) > RX_DATA_BUFFER_SIZE) RxBuf.writePtr = 0;
  }
  inline uint8_t rx_buffer_top(){
    uint8_t tmp = RxBuf.buf[RxBuf.readPtr];
    return tmp;
  }
  inline uint8_t rx_buffer_pop(){
    uint8_t tmp = RxBuf.buf[RxBuf.readPtr];
    if (++(RxBuf.readPtr) > RX_DATA_BUFFER_SIZE) RxBuf.readPtr = 0;
    return tmp;
  }
  
  inline uint16_t rx_current_crc(){
    uint16_t crc;
    uint8_t tmp = RxBuf.writePtr;
    tmp = (tmp == 0 ? RX_DATA_BUFFER_SIZE : tmp - 1);
    crc = RxBuf.buf[tmp] & 0x00ff;
    crc = (crc << 8) & 0xFF00;
    tmp = (tmp == 0 ? RX_DATA_BUFFER_SIZE : tmp - 1);
    crc |= (RxBuf.buf[tmp] & 0x00FF);
    return crc;
  }

  task void startDoneTask() {
    call SerialControl.start();
    signal SplitControl.startDone(SUCCESS);
  }

  task void stopDoneTask() {
    call SerialControl.stop();
    signal SplitControl.stopDone(SUCCESS);
  }
  
  command error_t SplitControl.start() {
    post startDoneTask();
    return SUCCESS;
  }

  void testOff() {
    bool turnOff = FALSE;
    atomic {
      if (TxState == TXSTATE_INACTIVE &&
	  RxState == RXSTATE_INACTIVE) {
	turnOff = TRUE;
      }
    }
    if (turnOff) {
      post stopDoneTask();
      atomic offPending = FALSE;
    }
    else {
      atomic offPending = TRUE;
    }
  }
    
  command error_t SplitControl.stop() {
    atomic {
      if (RxState == RXSTATE_NOSYNC) {
	RxState = RXSTATE_INACTIVE;
      }
    }
    atomic {
      if (TxState == TXSTATE_IDLE) {
	TxState = TXSTATE_INACTIVE;
      }
    }
    testOff();
    return SUCCESS;
  }

  /*
   *  Receive Path
   */ 
  
  
  async event void SerialFrameComm.delimiterReceived(){
    rx_state_machine(TRUE,0);
  }
  async event void SerialFrameComm.dataReceived(uint8_t data){
    rx_state_machine(FALSE,data);
  }

  bool valid_rx_proto(uint8_t proto){
    switch (proto){
    case SERIAL_PROTO_PACKET_ACK: 
      return TRUE;
    case SERIAL_PROTO_ACK:
    case SERIAL_PROTO_PACKET_NOACK:
    default: 
      return FALSE;
    }
  }

  void rx_state_machine(bool isDelimeter, uint8_t data){

    switch (RxState) {
      
    case RXSTATE_NOSYNC: 
      if (isDelimeter) {
        rxInit();
        RxState = RXSTATE_PROTO;
      }
      break;
      
    case RXSTATE_PROTO:
      if (!isDelimeter){
        RxCRC = crcByte(RxCRC,data);
        RxState = RXSTATE_TOKEN;
        RxProto = data;
        if (!valid_rx_proto(RxProto))
          goto nosync;
        // only supports serial proto packet ack
        if (RxProto != SERIAL_PROTO_PACKET_ACK){
          goto nosync;
        }
        if (signal ReceiveBytePacket.startPacket() != SUCCESS){
          goto nosync;
        }
      }      
      break;
      
    case RXSTATE_TOKEN:
      if (isDelimeter) {
        stats.serial_short_packets++;
        goto nosync;
      }
      else {
        RxSeqno = data;
        RxCRC = crcByte(RxCRC,RxSeqno);
        RxState = RXSTATE_INFO;
      }
      break;
      
    case RXSTATE_INFO:
      if (RxByteCnt < SERIAL_MTU){ 
        if (isDelimeter) { /* handle end of frame */
          if (RxByteCnt >= 2) {
            if (rx_current_crc() == RxCRC) {
              signal ReceiveBytePacket.endPacket(SUCCESS);
              ack_queue_push(RxSeqno);
              goto nosync;
            }
            else {
              stats.serial_crc_fail++;
              goto nosync;
            }
          }
          else {
            stats.serial_short_packets++;
            goto nosync;
          }
	}
        else { /* handle new bytes to save */
          if (RxByteCnt >= 2){ 
            signal ReceiveBytePacket.byteReceived(rx_buffer_top());
            RxCRC = crcByte(RxCRC,rx_buffer_pop());
          }
	  rx_buffer_push(data);
          RxByteCnt++;
        }
      }
      
      /* no valid message.. */
      else {
        stats.serial_proto_drops++;
        goto nosync;
       }
      break;
      
    default:      
      goto nosync;
    }
    goto done;

  nosync:
    /* reset all counters, etc */
    rxInit();
    call SerialFrameComm.resetReceive();
    signal ReceiveBytePacket.endPacket(FAIL);
    if (offPending) {
      RxState = RXSTATE_INACTIVE;
      testOff();
    }
    /* if this was a flag, start in proto state.. */
    else if (isDelimeter) {
      RxState = RXSTATE_PROTO;
    }
    
  done:
  }

  
  /*
   *  Send Path
   */ 


  void MaybeScheduleTx() {
    atomic {
      if (TxPending == 0) {
        if (post RunTx() == SUCCESS) {
          TxPending = 1;
        }
      }
    }
  }


  async command error_t SendBytePacket.completeSend(){
    bool ret = FAIL;
    atomic {
        TxBuf[TX_DATA_INDEX].state = BUFFER_COMPLETE;
        ret = SUCCESS;
    }
    return ret;
  }

  async command error_t SendBytePacket.startSend(uint8_t b){
    bool not_busy = FALSE;
    atomic {
      if (TxBuf[TX_DATA_INDEX].state == BUFFER_AVAILABLE){
        TxBuf[TX_DATA_INDEX].state = BUFFER_FILLING;
        TxBuf[TX_DATA_INDEX].buf = b;
        not_busy = TRUE;
      }
    }
    if (not_busy) {
      MaybeScheduleTx();
      return SUCCESS;
    }
    return EBUSY;

  }
  
  task void RunTx() {
    uint8_t idle;
    uint8_t done;
    uint8_t fail;
    
    /*
      the following trigger MaybeScheduleTx, which starts at most one RunTx:
      1) adding an ack to the ack queue (ack_queue_push())
      2) starting to send a packet (SendBytePacket.startSend())
      3) failure to send start delimiter in RunTx
      4) putDone: 
    */
    
    error_t result = SUCCESS;
    bool send_completed = FALSE;
    bool start_it = FALSE;
    
    atomic { 
      TxPending = 0;
      idle = (TxState == TXSTATE_IDLE);
      done = (TxState == TXSTATE_FINISH);
      fail = (TxState == TXSTATE_ERROR);
      if (done || fail){ 
        TxState = TXSTATE_IDLE;
        TxBuf[TxIndex].state = BUFFER_AVAILABLE;
      }
    }
    
    /* if done, call the send done */
    if (done || fail) {
      if (fail) atomic stats.serial_tx_fail++;
      TxSeqno++;
      if (TxProto == SERIAL_PROTO_ACK){
        ack_queue_pop();
      }
      else {
        result = done ? SUCCESS : FAIL;
        send_completed = TRUE;
      }
      idle = TRUE;
    }
    
    /* if idle, set up next packet to TX */ 
    if (idle) {
      bool goInactive;
      atomic goInactive = offPending;
      if (goInactive) {
        atomic TxState = TXSTATE_INACTIVE;
      }
      else {
        /* acks are top priority */
        uint8_t myAckState;
        uint8_t myDataState;
        atomic {
          myAckState = TxBuf[TX_ACK_INDEX].state;
          myDataState = TxBuf[TX_DATA_INDEX].state;
        }
        if (!ack_queue_is_empty() && myAckState == BUFFER_AVAILABLE) {
          atomic {
            TxBuf[TX_ACK_INDEX].state = BUFFER_COMPLETE;
            TxBuf[TX_ACK_INDEX].buf = ack_queue_top();
          }
          TxProto = SERIAL_PROTO_ACK;
          TxIndex = TX_ACK_INDEX;
          start_it = TRUE;
        }
        else if (myDataState == BUFFER_FILLING || myDataState == BUFFER_COMPLETE){
          TxProto = SERIAL_PROTO_PACKET_NOACK;
          TxIndex = TX_DATA_INDEX;
          start_it = TRUE;
        }
        else {
          /* nothing to send now.. */
        }
      }
    }
    else {
      /* we're in the middle of transmitting */
    }
    
    if (send_completed){
      signal SendBytePacket.sendCompleted(result);
    }
    
    if (TxState == TXSTATE_INACTIVE) {
      testOff();
      return;
    }
    
    if (start_it){
      /* OK, start transmitting ! */
      atomic { 
        TxCRC = 0;
        TxByteCnt = 0;
        TxState = TXSTATE_PROTO; 
      }
      if (call SerialFrameComm.putDelimiter() != SUCCESS) {
        atomic TxState = TXSTATE_ERROR; 
        MaybeScheduleTx();
      }
    }
    
  }
  
  async event void SerialFrameComm.putDone() {
    {
      error_t TxResult = SUCCESS;
      
      switch (TxState) {
        
      case TXSTATE_PROTO:

         TxResult = call SerialFrameComm.putData(TxProto);
#ifdef NO_TX_SEQNO
        TxState = TXSTATE_INFO;
#else
        TxState = TXSTATE_SEQNO;
#endif
        TxCRC = crcByte(TxCRC,TxProto);
        break;
        
      case TXSTATE_SEQNO:
        TxResult = call SerialFrameComm.putData(TxSeqno);
        TxState = TXSTATE_INFO;
        TxCRC = crcByte(TxCRC,TxSeqno);
        break;
        
      case TXSTATE_INFO:
        TxResult = call SerialFrameComm.putData(TxBuf[TxIndex].buf);
        TxCRC = crcByte(TxCRC,TxBuf[TxIndex].buf);
        ++TxByteCnt;

        if (TxBuf[TxIndex].state == BUFFER_COMPLETE || TxByteCnt >= SERIAL_MTU){
          TxState = TXSTATE_FCS1;
        }
        else { /* never called on ack b/c ack is BUFFER_COMPLETE initially */
          TxBuf[TxIndex].buf = signal SendBytePacket.nextByte();
        }
        break;
        
      case TXSTATE_FCS1:
        TxResult = call SerialFrameComm.putData(TxCRC & 0xff);
        TxState = TXSTATE_FCS2;
        break;
        
      case TXSTATE_FCS2:
        TxResult = call SerialFrameComm.putData((TxCRC >> 8) & 0xff);
        TxState = TXSTATE_ENDFLAG;
        break;
        
      case TXSTATE_ENDFLAG:
        TxResult = call SerialFrameComm.putDelimiter();
        TxState = TXSTATE_ENDWAIT;
        break;
        
      case TXSTATE_ENDWAIT:
        TxState = TXSTATE_FINISH;
      case TXSTATE_FINISH:
      case TXSTATE_ERROR:
      default:
        TxResult = FAIL; 
        break;
      }
      
      if (TxResult != SUCCESS) {
        TxState = TXSTATE_ERROR;
        MaybeScheduleTx();
      }
    }
  }

  
 default event void SplitControl.startDone(error_t err) {}
 default event void SplitControl.stopDone(error_t err) {}
}
