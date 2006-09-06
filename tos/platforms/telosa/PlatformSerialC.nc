
configuration PlatformSerialC {
  provides interface StdControl;
  provides interface SerialByteComm;
}
implementation {
  components new Msp430Uart1C() as UartC, TelosSerialP;

  StdControl = TelosSerialP;
  SerialByteComm = UartC;
  TelosSerialP.Msp430UartConfigure <- UartC.Msp430UartConfigure;
  TelosSerialP.Resource -> UartC.Resource;
}
