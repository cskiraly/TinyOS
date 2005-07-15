generic configuration UARTInstanceC(uint8_t offset, uint8_t id) {
  provides {
    interface Send;
    interface Receive;
  }
}
implementation {
  components UARTDispatcherM;
  components new UARTKeyM(offset);
  components new UARTSendBridge(offset);

  UARTDispatcherM.Key[id] = UARTKeyM;
  Send = UARTSendBridge;
  UARTSendBridge.OffsetSend -> UARTDispatcherM.OffsetSend[id];
  Receive = UARTDispatcherM.Receive[id];
}

