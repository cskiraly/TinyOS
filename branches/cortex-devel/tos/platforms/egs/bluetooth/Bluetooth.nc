interface Bluetooth {

  command void init();
  event void initDone(error_t error);

  command void HCMstart();
  event void HCMstartDone();

  command void HCMstop();
  event void HCMstopDone();

  event void connectionBTModule();
  event void setMasterDone();
  
  command void setLocalName(uint8_t* name, uint8_t length);
  event void setLocalNameDone();

  command void setSlave();
  event void setSlaveDone();
  command void setSecurityLevel(uint8_t a, uint8_t b);

  event void setSecurityLevelDone();

  event void setConnectRuleDone();

  command void sendBTData(uint8_t* buf, uint8_t length);
  event void sendBTDataDone();
  event void recvBTData(uint8_t buf);
  

  /*

  command error_t bluetoothModeSelect(uint8_t mode);
  command error_t write(uint8_t *buf, uint16_t len);
  command void nodeDiscovery(bool discover);
  command error_t nodeConnect();
  command void setBaudrate(uint32_t br);

  event void writeDone(error_t error);
  event void connectionResult(bool success);
  event void dataReceived(uint8_t data);

  */

}