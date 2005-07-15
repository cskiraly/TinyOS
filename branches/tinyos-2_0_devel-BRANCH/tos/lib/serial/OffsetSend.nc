interface OffsetSend {
  command error_t send(message_t* msg, uint8_t offset, uint8_t len);
  command error_r cancel(message_t* msg);
  event void sendDone(message_t* msg, error_t error);
}
