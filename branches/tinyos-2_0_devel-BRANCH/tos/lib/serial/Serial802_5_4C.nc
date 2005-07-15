configuration Serial802_15_4C {
  provides {
    interface Send;
    interface Receive;
  }
}
implementation { 
  components SerialInfo802_15_4C, SerialDispatcherC;

  Send = SerialDispatcherC.Send[TOS_SERIAL_802_15_4_ID];
  Receive = SerialDispatcherC.Receive[TOS_SERIAL_802_15_4_ID];
  UartDispatcherC.SerialPacketInfo[TOS_SERIAL_802_15_4_ID] -> SerialPacketInfo802_15_4C;
}
