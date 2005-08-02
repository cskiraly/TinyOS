includes Serial;

module HdlcTranslateM {
  provides interface SerialFrameComm;
  uses {
    interface SerialByteComm;
    interface Leds;
  }
}

implementation {
  typedef struct {
    uint8_t sendEscape:1;
    uint8_t receiveEscape:1;
  } HdlcState;
  
  norace uint8_t debugCnt = 0;
  norace HdlcState state = {0,0};
  norace uint8_t txTemp;

  
  // TODO: add reset for when SerialM goes no-sync.
  async command void SerialFrameComm.resetReceive(){
    state.receiveEscape = 0;
  }
  async command void SerialFrameComm.resetSend(){
    state.sendEscape = 0;
  }
  async event void SerialByteComm.get(uint8_t data) {
    debugCnt++;
    // 7E 41 0E 05 04 03 02 01 00 01 8F 7E
/*     if (debugCnt == 1 && data == 0x7E) call Leds.led0On(); */
/*     if (debugCnt == 2 && data == 0x41) call Leds.led1On(); */
/*     if (debugCnt == 3 && data == 0x0E) call Leds.led2On(); */

    if (data == HDLC_FLAG_BYTE) {
      //call Leds.led1On();
      signal SerialFrameComm.delimiterReceived();
      return;
    }
    else if (data == HDLC_CTLESC_BYTE) {
      //call Leds.led1On();
      state.receiveEscape = 1;
      return;
    }
    else if (state.receiveEscape) {
      //call Leds.led1On();
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
    else {
      return call SerialByteComm.put(data);
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
