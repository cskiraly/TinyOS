interface UARTPacketInfo {
  command uint8_t offset();
  command uint8_t dataLinkLength(message_t* msg, uint8_t upperLen);
  comment uint8_t upperLength(message_t* msg, uint8_t dataLinkLen);
}
