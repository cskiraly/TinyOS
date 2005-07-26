includes Serial;

generic module SerialDispatcherM() {
  provides {
    interface Receive[uart_id_t id];
    interface Send[uart_id_t id];
  }
  uses {
    interface SerialPacketInfo as PacketInfo[uart_id_t id];
    interface ReceiveBytePacket;
    interface SendBytePacket;
  }
}
implementation {

  typedef enum {
    SEND_STATE_IDLE = 0,
    SEND_STATE_BEGIN = 1,
    SEND_STATE_DATA = 2
  } send_state_t;

  enum {
    RECV_STATE_IDLE = 0,
    RECV_STATE_BEGIN = 1,
    RECV_STATE_DATA = 2,
  }; 
  
  typedef struct {
    uint8_t which:1;
    uint8_t bufZeroLocked:1;
    uint8_t bufOneLocked:1;
    uint8_t state:2;
  } recv_state_t;
  
  // We are not busy, the current buffer to use is zero,
  // neither buffer is locked, and we are idle
  recv_state_t receiveState = {0, 0, 0, RECV_STATE_IDLE};
  uint8_t recvType = TOS_SERIAL_UNKNOWN_ID;
  uint8_t recvIndex = 0;

  /* This component provides double buffering. */
  message_t messages[2];     // buffer allocation
  message_t* messagePtrs[2] = { &messages[0], &messages[1]};
  
  // We store a separate receiveBuffer variable because indexing
  // into a pointer array can be costly, and handling interrupts
  // is time critical.
  uint8_t* receiveBuffer = (uint8_t*)(&messages[0]);

  uint8_t *sendBuffer = NULL;
  send_state_t sendState = SEND_STATE_IDLE;
  uint8_t sendLen = 0;
  uint8_t sendIndex = 0;
  norace error_t sendError = SUCCESS;
  bool sendCancelled = FALSE;
  uint8_t sendId = 0;

  command error_t Send.send[uint8_t id](message_t* msg, uint8_t len) {
    uint8_t myState;
    atomic {
      myState = sendState;
    }
    if (myState != SEND_STATE_IDLE) {
      return EBUSY;
    }
    else {
      atomic {
        sendState = SEND_STATE_DATA;
        sendId = id;
        sendError = SUCCESS;
        sendCancelled = FALSE;
        sendBuffer = (uint8_t*)msg;
        sendLen = call PacketInfo.dataLinkLength[id](msg, len);
        sendIndex = call PacketInfo.offset[id]();
      }
      if (call SendBytePacket.startSend(id) == SUCCESS) {
        return SUCCESS;
      }
      else {
        atomic {
          sendState = SEND_STATE_IDLE;
        }
        return FAIL;
      }
    }
  }

  task void signalSendDone(){
    bool cancelled;
    error_t error;
    atomic {
      sendState = SEND_STATE_IDLE;
      error = sendError;
      cancelled = sendCancelled;
    }
    if (cancelled) error = ECANCEL;
    signal Send.sendDone[sendId]((message_t *)sendBuffer, error);
  }

  command error_t Send.cancel[uint8_t id](message_t *msg){
    uint8_t myState;
    uint8_t *buf;
    uint8_t sid;

    atomic {
      myState = sendState;
      buf = sendBuffer;
      sid = sendId;
    }
    if (myState == SEND_STATE_DATA && buf == ((uint8_t *)msg) && id == sid){
      call SendBytePacket.completeSend();
      atomic sendCancelled = TRUE;
      return SUCCESS;
    }
    return FAIL;
  }

  async event uint8_t SendBytePacket.nextByte() {
    uint8_t b;
    uint8_t indx;
    atomic {
      b = sendBuffer[sendIndex];
      sendIndex++;
      indx = sendIndex;
    }
    if (indx >= sendLen) {
      call SendBytePacket.completeSend();
      return 0;
    }
    else {
      return b;
    }
  }
  async event void SendBytePacket.sendCompleted(error_t error){
    sendError = error;
    post signalSendDone();
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
  
  async event error_t ReceiveBytePacket.startPacket() {
    error_t result = SUCCESS;
    atomic {
      if (!isCurrentBufferLocked()) {
        // We are implicitly in RECV_STATE_IDLE, as it is the only
        // way our current buffer could be unlocked.
        lockCurrentBuffer();
        receiveState.state = RECV_STATE_BEGIN;
        recvIndex = 0;
        recvType = TOS_SERIAL_UNKNOWN_ID;
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
        recvIndex = call PacketInfo.offset[b]();
        recvType = b;
        break;
        
      case RECV_STATE_DATA:
        if (recvIndex < sizeof(message_t)) {
          receiveBuffer[recvIndex] = b;
          recvIndex++;
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
  
  async event void ReceiveBytePacket.endPacket(error_t result) {
    // These are all local variables to release component state that
    // will allow the component to start receiving serial packets
    // ASAP.
    //
    // We need myWhich in case we happen to receive a whole new packet
    // before the signal returns, at which point receiveState.which
    // might revert back to us (via receiveBufferSwap()).
    
    uart_id_t myType;   // What is the type of the packet in flight? 
    uint8_t myWhich;  // Which buffer ptr entry is it?
    uint8_t mySize;   // How large is it?
    message_t* myBuf; // A pointer, for buffer swapping

    // First, copy out all of the important state so we can receive
    // the next packet. Then do a receiveBufferSwap, which will
    // tell the component to use the other available buffer.
    // If the buffer is 
    atomic {
      myType = recvType;
      myWhich = receiveState.which;
      myBuf = (message_t*)receiveBuffer;
      mySize = recvIndex;
      receiveBufferSwap();
      receiveState.state = RECV_STATE_IDLE;
    }

    mySize -= call PacketInfo.offset[myType]();
    mySize = call PacketInfo.upperLength[myType](myBuf, mySize);

    if (result == SUCCESS){
      // TODO is the payload the same as the message?
      myBuf = signal Receive.receive[myType](myBuf, myBuf, mySize);
    }
    atomic {
      messagePtrs[myWhich] = myBuf;
      if (myWhich) {
        unlockBuffer(myWhich);
      }
    }
  }
  default async command uint8_t PacketInfo.offset[uart_id_t id](){
    return 0;
  }
  default async command uint8_t PacketInfo.dataLinkLength[uart_id_t id](message_t *msg,
                                                          uint8_t upperLen){
    return 0;
  }
  default async command uint8_t PacketInfo.upperLength[uart_id_t id](message_t *msg,
                                                       uint8_t dataLinkLen){
    return 0;
  }


  default event message_t *Receive.receive[uart_id_t idxxx](message_t *msg,
                                                         void *payload,
                                                         uint8_t len){
    return msg;
  }
  default event void Send.sendDone[uart_id_t idxxx](message_t *msg, error_t error){
    return;
  }

  
}
