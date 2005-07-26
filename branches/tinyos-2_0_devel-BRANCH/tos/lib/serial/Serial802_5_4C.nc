includes Serial;
configuration Serial802_15_4C {
  provides {
    interface Send;
    interface Receive;
  }
  uses interface Leds;
}
implementation { 
  components SerialPacketInfo802_15_4C as Info, SerialDispatcherC;

  Init = SerialDispatcherC;
  Leds = SerialDispatcherC;
  Send = SerialDispatcherC.Send[TOS_SERIAL_802_15_4_ID];
  Receive = SerialDispatcherC.Receive[TOS_SERIAL_802_15_4_ID];
  SerialDispatcherC.SerialPacketInfo[TOS_SERIAL_802_15_4_ID] -> Info;
}
