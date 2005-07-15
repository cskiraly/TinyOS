/* THis is the interface that H provides and F uses. */
   
interface SerialFrameComm {
  async command error_t putDelimiter();
  async command error_t putData(uint8_t data);
  async event void delimiterReceived();
  async event void dataReceived(uint8_t data);
  async event void putDone();
}
