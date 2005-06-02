interface ByteRadio
{
  event void rts();
  async command void cts();
  async event void sendDone();

  async command void setAck(bool on);
  async command void setPreambleLength(uint16_t bytes);
  async command uint16_t getPreambleLength();

  async command void cd();
  async event void rxDone();
  async event void rxAborted();
}
