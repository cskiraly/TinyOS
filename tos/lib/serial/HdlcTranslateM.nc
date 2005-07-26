includes Serial;

module HdlcTranslateM {
  provides interface SerialFrameComm;
  uses interface SerialByteComm;
}

implementation {
  typedef struct {
    uint8_t sendEscape:1;
    uint8_t receiveEscape:1;
  } HdlcState;
  
  norace HdlcState state = {0,0};
  norace uint8_t txTemp;
  
  // TODO: add reset for when SerialM goes no-sync.

  async event void SerialByteComm.get(uint8_t data) {
    if (data == HDLC_FLAG_BYTE) {
      signal SerialFrameComm.delimiterReceived();
      return;
    }
    else if (data == HDLC_CTLESC_BYTE) {
      state.receiveEscape = 1;
      return;
    }
    else if (state.receiveEscape) {
      state.receiveEscape = 0;
      data = data ^ 0x20;
    }
    signal SerialFrameComm.dataReceived(data);
  }

  async command error_t SerialFrameComm.putDelimiter() {
    state.sendEscape = 0;
    return call SerialByteComm.put(HDLC_FLAG_BYTE);
  }
  
  async command error_t SerialFrameComm.putData(uint8_t data) {
    if (data == HDLC_CTLESC_BYTE || data == HDLC_FLAG_BYTE) {
      state.sendEscape = 1;
      txTemp = data ^ 0x20;
      return call SerialByteComm.put(HDLC_CTLESC_BYTE);
    }
  }

  async event void SerialByteComm.putDone() {
    if (state.sendEscape) {
      state.sendEscape = 0;
      call SerialByteComm.put(txTemp);
    }
    else {
      signal SerialFrameComm.putDone();
    }
  }
}
