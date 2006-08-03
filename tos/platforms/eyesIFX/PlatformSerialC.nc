configuration PlatformSerialC {
  provides interface StdControl;
  provides interface SerialByteComm;
}
implementation {
  components new Msp430Uart1C() as UartC, eyesIFXSerialP;

  SerialByteComm = UartC;
  StdControl = eyesIFXSerialP;
  eyesIFXSerialP.Msp430UartConfigure <- UartC.Msp430UartConfigure;
  eyesIFXSerialP.Resource -> UartC.Resource;
}
