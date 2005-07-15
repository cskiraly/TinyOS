/* This is an interface that F provides and D uses. I hope this one is
   pretty clear. */

interface ReceiveBytePacket {
  async event void startPacket();
  async event void byteReceived(uint8_t b);
  async event void endPacket();
}

