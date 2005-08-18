module PlatformSerialC {
  provides interface Init;
  provides interface SerialByteComm;
}
implementation {
  async command error_t SerialByteComm.put(uint8_t data) {
    return SUCCESS;
  }

  command error_t Init.init() {
    return SUCCESS;
  }
}
