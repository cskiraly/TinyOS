generic module SerialDispatcherM {
  provides {
    interface Init;
    interface Receive[uart_id_t];
    interface Send[uart_id_t];
  }
  uses {
    interface SerialPacketInfo as PacketInfo[uart_id_t];
    interface ReceiveBytePacket;
    interface SendBytePacket;
  }
}
implementation {
  state_t state;
  uint8_t currentRecvType;
  uint8_t recvIndex;
  
  message_t messages[2]; // double buffering
    /*
      receive pseudocode:
      when I receive the first byte of a UART frame, store it
      in currentRecvType and call UARTPacketInfo.offset with it as a key to 
      determine the initial value of recvIndex. mark recv state to be busy.
      
      subsequent bytes are read into the current message buffer,
      at index, until we get an end of frame delimiter. 
      If recvIndex > sizeof(message_t), drop the packet.
      
      Set up the next buffer for reception, set recv state to idle,
      and signal reception. The length passed to the higher layer is
      PacketInfo[id].upperLength(msg, len), where len is the size of the
      UART frame. 
      
      
      send pseudocode:
      if already sending return EBUSY
      otherwise store offset and type in currentSendType and
      currentSendIndex.
      spool out the bytes
      (the number of bytes to send is PacketInfo[id].dataLinkLength(msg, len),
      where len is the number passed in from the higher layer)
      signal sendDone.
    */

  event error_t Send.send[uint8_t id](message_t* msg, uint8_t len) {
    uint8_t myState;
    atomic {
      myState = sendState;
    }
    if (myState != STATE_IDLE) {
      return EBUSY;
    }
    else {
      atomic {
	sendState = STATE_DATA;
	sendBuffer = (uint8_t*)msg;
	sendLen = call PacketInfo.dataLinkLength[id](msg, len);
	sendIndex = call PacketInfo.offset[id]();
      }
      if (call SendBytePacket.startSend(id) == SUCCESS) {
	return SUCCESS;
      }
      else {
	atomic {
	  sendState = STATE_IDLE;
	}
	return FAIL;
      }
    }
  }

  async event uint8_t nextByte() {
    uint8_t b;
    atomic {
      sendBuffer[sendIndex];
      sendIndex++;
    }    
  }
  
  enum {
    STATE_IDLE,
    STATE_BEGIN,
    STATE_DATA
  } ReceiveState;
    
  async event void ReceiveBytePacket.startPacket() {
    atomic {
      receiveState = STATE_BEGIN;
      receiveIndex = 0;
      receiveType = TOS_SERIAL_UNKNOWN_ID;
    }
  }
  async event void ReceiveBytePacket.byteReceived(uint8_t b) {
    atomic {
      if (receiveState == STATE_BEGIN) {
        receiveState = STATE_DATA;
	receiveIndex = call SerialPacketInfo[b].offset();
	receiveType = b;
      }
      else {
	if (receiveIndex < sizeof(message_t)) {
	  receiveBuffer[receiveIndex] = b;
	  receiveIndex++;
	}
      }
    }
  }
  async event void ReceiveBytePacket.endPacket() {
    uint8_t myType;
    message_t* myBuf;
    uint8_t mySize;
    atomic {
      myType = receiveType;
      myBuf = (message_t*)receiveBuffer;
      mySize = receiveIndex - call SerialPacketInfo[receiveType].offset();
      receiveBufferSwap();
      receiveState = STATE_IDLE;
    }
    mySize = call SerialPacketInfo[myType].upperLength(myBuf, mySize);

    // This should either be an async receive or should cause a task to be
    // posted
    signal Receive.receive[myType](myBuf, mySize);
  }

  
}
