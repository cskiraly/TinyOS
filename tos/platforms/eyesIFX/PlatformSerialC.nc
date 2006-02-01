configuration PlatformSerialC {
  provides interface Init;
  provides interface StdControl;
  provides interface SerialByteComm;
}
implementation {
  components new Uart1C() as UartC, eyesIFXSerialP;

  Init = UartC;
  StdControl = UartC;
  SerialByteComm = UartC;
  eyesIFXSerialP.Resource -> UartC.Resource;
}
