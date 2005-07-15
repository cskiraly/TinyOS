generic module UARTSendBridgeM (uint8_t offset) {
  provides interface Send;
  uses interface OffsetSend;
}
implementation {
  command error_t Send.send(message_t* m, uint8_t len) {
    return call OffsetSend.send(m, len, offset);
  }

  event void OffsetSend.sendDone(message_t* m, error_t err) {
    return Send.sendDone(m, err);
  }
}
