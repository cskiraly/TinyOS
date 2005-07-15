generic module UARTDispatcherM {
  provides {
    interface Init;
    interface Receive[uart_id_t];
    interface OffsetSend[uart_id_t];
  }
  uses {
    interface Key<uint8_t> as OffsetKey[uart_id_t];
    interface HPLUART as SerialByteComm;
  }
}
implementation {
  state_t state;
  uint8_t currentRecvType;
  uint8_t recvIndex;

  message_t messages[2] // double buffering

  receive pseudocode:
  when I receive the first byte of a UART frame, store it
  in currentRecvType and call UARTOffset with it as a key to 
  determine the initial value of recvIndex. mark recv state to be busy.

  subsequent bytes are read into the current message buffer,
  at index, until we get an end of frame delimiter. 
  If recvIndex > sizeof(message_t), drop the packet.

  Set up the next buffer for reception, set recv state to idle,
  and signal reception. 

  send pseudocode:
  if already sending return EBUSY
  otherwise store offset and type in currentSendType and
  currentSendIndex.
  spool out the bytes
  signal sendDone.

}
