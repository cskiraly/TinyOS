generic configuration Uart1C() {
  provides interface Init;
  provides interface Resource;
  provides interface StdControl;
  provides interface SerialByteComm;
}

implementation {

  enum {
    CLIENT_ID = unique( "Msp430Usart1.Resource" ),
  };

  components Msp430Uart1C as UartC;

  Init = UartC;
  Resource = UartC.Resource[ CLIENT_ID ];
  StdControl = UartC;
  SerialByteComm = UartC.SerialByteComm;
}
