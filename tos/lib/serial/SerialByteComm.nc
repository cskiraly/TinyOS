// Basically the same as HPLUART except no start/stop
interface SerialByteComm {
  async command error_t put(uint8_t data);
  async event void get(uint8_t data);
  async event void putDone();
}
