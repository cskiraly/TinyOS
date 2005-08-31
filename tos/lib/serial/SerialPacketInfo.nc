interface SerialPacketInfo {
  async command uint8_t offset();
  async command uint8_t dataLinkLength(message_t* msg, uint8_t upperLen);
  async command uint8_t upperLength(message_t* msg, uint8_t dataLinkLen);
}
