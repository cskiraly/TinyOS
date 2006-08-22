configuration PlatformSerialC {
  provides interface StdControl;
  provides interface SerialByteComm;
}
implementation {
  components new Msp430Uart1C() as UartC, TinyNodeSerialP;

  StdControl = TinyNodeSerialP;
  SerialByteComm = UartC;
  TinyNodeSerialP.Resource -> UartC.Resource;
  TinyNodeSerialP.Msp430UartConfigure <- UartC.Msp430UartConfigure;
}
