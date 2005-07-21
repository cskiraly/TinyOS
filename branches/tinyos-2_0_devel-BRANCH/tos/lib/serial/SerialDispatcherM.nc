generic module SerialDispatcherM {
  provides {
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

  typedef enum {
    SEND_STATE_IDLE,
    SEND_STATE_BEGIN,
    SEND_STATE_DATA
  } send_state_t;

  enum {
    RECV_STATE_IDLE = 0,
    RECV_STATE_BEGIN = 1,
    RECV_STATE_DATA = 2,
  } 
  
  typedef struct {
    uint8_t which:1;
    uint8_t bufZeroLocked:1;
    uint8_t bufOneLocked:1;
    uint8_t state: 2;
  } recv_state_t;
  
  // We are not busy, the current buffer to use is zero,
  // neither buffer is locked, and we are idle
  recv_state_t receiveState = {0, 0, 0, RECV_STATE_IDLE};
  uint8_t currentRecvType = TOS_SERIAL_UNKNOWN_ID;
  uint8_t recvIndex = 0;
  // We store a separate receiveBuffer variable because indexing
  // into a pointer array can be costly, and handling interrupts
  // is time critical.
  uint8_t* receiveBuffer = (uint8_t*)(messagePtrs[0]);


  /* This component provides double buffering. */
  message_t messages[2];     // buffer allocation
  message_t* messagePtrs[2] = { &messages[0], &messages[1]};
  
  send_state_t sendState = SEND_STATE_IDLE;

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

  async event uint8_t SendBytePacket.nextByte() {
    uint8_t b;
    uint8_t index;
    atomic {
      b = sendBuffer[sendIndex];
      sendIndex++;
      index = sendIndex;
    }
    if (index >= sendLen) {
      call SendBytePacket.sendComplete();
      return 0;
    }
    else {
      return b;
    }
  }

  bool isCurrentBufferLocked() {
    return (receiveState.which)? receiveState.bufZeroLocked : receiveState.bufOneLocked;
  }

  void lockCurrentBuffer() {
    if (receiveState.which) {
      receiveState.bufOneLocked = 1;
    }
    else {
      receiveState.bufZeroLocked = 1;
    }
  }

  void unlockBuffer(uint8_t which) {
    if (which) {
      receiveState.bufOneLocked = 0;
    }
    else {
      receiveState.bufZeroLocked = 0;
    }
  }
  
  void receiveBufferSwap() {
    receiveState.which = (receiveState.which)? 1: 0;
    receiveBuffer = (uint8_t*)(messagePtrs[receiveState.which]);
  }
  
  async event void ReceiveBytePacket.startPacket() {
    error_t result = SUCCESS;
    atomic {
      if (!isCurrentBufferLocked()) {
        // We are implicitly in RECV_STATE_IDLE, as it is the only
        // way our current buffer could be unlocked.
        lockCurrentBuffer();
        receiveState = RECV_STATE_BEGIN;
        receiveIndex = 0;
        receiveType = TOS_SERIAL_UNKNOWN_ID;
      }
      else {
        result = EBUSY;
      }
    }
    return result;
  }

  async event void ReceiveBytePacket.byteReceived(uint8_t b) {
    atomic {
      switch (receiveState.state) {
      case RECV_STATE_BEGIN:
	receiveState.state = RECV_STATE_DATA;
	receiveIndex = call SerialPacketInfo[b].offset();
	receiveType = b;
	break;
	
      case RECV_STATE_DATA:
	if (receiveIndex < sizeof(message_t)) {
	  receiveBuffer[receiveIndex] = b;
	  receiveIndex++;
	}
	else {
	  // Drop extra bytes that do not fit in a message_t.
	  // We assume that either the higher layer knows what to
	  // do with partial packets, or performs sanity checks (e.g.,
	  // CRC).
	}
	break;
	
      case RECV_STATE_IDLE:
      default:
	// Do nothing. This case can be reached if the component
	// does not have free buffers: it will ignore a packet start
	// and stay in the IDLE state.
      }
    }
  }

  async event void ReceiveBytePacket.endPacket() {
    // These are all local variables to release component state that
    // will allow the component to start receiving serial packets
    // ASAP.
    //
    // We need myWhich in case we happen to receive a whole new packet
    // before the signal returns, at which point receiveState.which
    // might revert back to us (via receiveBufferSwap()).
    
    uint8_t myType;   // What is the type of the packet in flight? 
    uint8_t myWhich;  // Which buffer ptr entry is it?
    uint8_t mySize;   // How large is it?
    message_t* myBuf; // A pointer, for buffer swapping

    // First, copy out all of the important state so we can receive
    // the next packet. Then do a receiveBufferSwap, which will
    // tell the component to use the other available buffer.
    // If the buffer is 
    atomic {
      myType = receiveType;
      myWhich = receiveState.which;
      myBuf = (message_t*)receiveBuffer;
      mySize = receiveIndex;
      receiveBufferSwap();
      receiveState.state = RECV_STATE_IDLE;
    }

    mySize -= call SerialPacketInfo[myType].offset();
    mySize = call SerialPacketInfo[myType].upperLength(myBuf, mySize);

    myBuf = signal Receive.receive[myType](myBuf, mySize);
    atomic {
      messagePtrs[myWhich] = myBuf;
      if (myWhich) {
	unlockBuffer(myWhich);
      }
    }
  }

  
}
