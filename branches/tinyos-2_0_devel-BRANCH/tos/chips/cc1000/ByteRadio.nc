interface ByteRadio
{
  command void rts();
  async event void cts();
  async command void sendDone();

  async event void setAck(bool on);
  async event void setPreambleLength(uint16_t bytes);
  async event uint16_t getPreambleLength();

  async event void cd();
  async command void rxDone();
  async command void rxAborted();
}
