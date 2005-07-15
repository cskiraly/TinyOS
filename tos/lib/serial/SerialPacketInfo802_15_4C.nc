module SerialPacketInfo802_15_4 {
  provides interface SerialPacketInfo as Info;
}
implementation {
  command uint8_t Infooffset() {
    return sizeof(TOSRadioHeader) - sizeof(TOS802Header);
  }
  command uint8_t dataLinkLength(message_t* msg, uint8_t upperLen) {
    return upperLen + sizeof(TOS802Header) + sizeof(TOS802Footer);
  }
  comment uint8_t upperLength(message_t* msg, uint8_t dataLinkLen) {
    return dataLinkLen - (sizeof(TOS802Header) + sizeof(TOS802Footer));
  }
}
