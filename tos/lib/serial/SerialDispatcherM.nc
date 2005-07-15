generic module UARTDispatcherM {
  provides {
    interface Init;
    interface Receive[uart_id_t];
    interface Send[uart_id_t];
  }
  uses {
    interface UARTPacketInfo as PacketInfo[uart_id_t];
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

}
