configuration UART802_15_4C {
  provides {
    interface Send;
    interface Receive;
  }
}
implementation { 
  components new UARTInstanceM(sizeof(TOSRadioHeader) - sizeof(TOS802Header), TOS_UART_802_ID);

  Send = UARTInstanceM;
  Receive = UARTInstanceM;
}
