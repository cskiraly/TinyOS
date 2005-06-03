interface ByteRadio
{
  event void rts();
  async command void cts();
  async event void sendDone();

  async command void setAck(bool on);
  async command void setPreambleLength(uint16_t bytes);
  async command uint16_t getPreambleLength();
  async command message_t *getTxMessage();

  async command void listen();
  async command void off();
  async event void idleByte(bool preamble);

  async command bool syncing();
  async event void rx();
  async event void rxDone();
}
