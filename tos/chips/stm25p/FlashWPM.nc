
module FlashWPM {
  provides {
    interface FlashWP;
    interface StdControl;
  }
  uses {
    interface HALSTM25P;
  }
}

implementation {

  uint8_t state;

  enum {
    S_IDLE,
    S_CLR,
    S_SET,
  };

  command result_t StdControl.init() {
    state = S_IDLE;
    return SUCCESS;
  }

  command result_t StdControl.start() { return SUCCESS; }
  command result_t StdControl.stop() { return SUCCESS; }

  command result_t FlashWP.clrWP() {
    state = S_CLR;
    if (call HALSTM25P.writeSR(0x0) == FAIL) {
      state = S_IDLE;
      return FAIL;
    }
    return SUCCESS;
  }

  command result_t FlashWP.setWP() {
    state = S_SET;
    if (call HALSTM25P.writeSR(0x84) == FAIL) {
      state = S_IDLE;
      return FAIL;
    }
    return SUCCESS;
  }

  event void HALSTM25P.writeSRDone(result_t result) {
    uint8_t tmpState = state;
    state = S_IDLE;
    switch(tmpState) {
    case S_CLR: signal FlashWP.clrWPDone(result); break;
    case S_SET: signal FlashWP.setWPDone(result); break;
    }
  }

  event void HALSTM25P.readDone(result_t result) { ; }
  event void HALSTM25P.pageProgramDone(result_t result) { ; }
  event void HALSTM25P.sectorEraseDone(result_t result) { ; }
  event void HALSTM25P.bulkEraseDone(result_t result) { ; }
  event void HALSTM25P.computeCrcDone(result_t result, uint16_t crc) { ; }

}
