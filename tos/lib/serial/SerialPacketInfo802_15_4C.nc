module SerialPacketInfo802_15_4C {
  provides interface SerialPacketInfo as Info;
}
implementation {
  async command uint8_t Info.offset() {
    return sizeof(TOSRadioHeader) - sizeof(TOS802Header);
  }
  async command uint8_t Info.dataLinkLength(message_t* msg, uint8_t upperLen) {
    return upperLen + sizeof(TOS802Header) + sizeof(TOS802Footer);
  }
  async command uint8_t Info.upperLength(message_t* msg, uint8_t dataLinkLen) {
    return dataLinkLen - (sizeof(TOS802Header) + sizeof(TOS802Footer));
  }
}
