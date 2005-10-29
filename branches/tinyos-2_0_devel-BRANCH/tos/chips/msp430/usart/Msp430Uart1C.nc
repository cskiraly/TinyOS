configuration Msp430Uart1C {
  provides interface Init;
  provides interface Resource[ uint8_t id ];
  provides interface StdControl;
  provides interface SerialByteComm;
}
implementation {
  components new Msp430UartP() as UartP;
  Init = UartP;
  StdControl = UartP;
  SerialByteComm = UartP;

  components HplMsp430Usart1C as HplUsart;
  Resource = HplUsart;
  UartP.HplUsart -> HplUsart;
}
   
