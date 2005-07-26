module SerialPacketInfoActiveMessageC {
  provides interface SerialPacketInfo as Info;
}
implementation {
  async command uint8_t Info.offset() {
    return sizeof(TOSRadioHeader) - sizeof(CC1KHeader);
  }
  async command uint8_t Info.dataLinkLength(message_t* msg, uint8_t upperLen) {
    return upperLen + sizeof(CC1KHeader) + sizeof(CC1KFooter);
  }
  async command uint8_t Info.upperLength(message_t* msg, uint8_t dataLinkLen) {
    return dataLinkLen - (sizeof(CC1KHeader) + sizeof(CC1KFooter));
  }
}

