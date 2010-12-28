interface Bluetooth {
  command error_t bluetoothModeSelect(uint8_t mode);
  command error_t write(uint8_t *buf, uint16_t len);
  command void nodeDiscovery(bool discover);
  command error_t nodeConnect();
  command void setBaudrate(uint32_t br);

  event void writeDone(error_t error);
  event void connectionResult(bool success);
  event void dataReceived(uint8_t data);
}