includes Serial;
configuration SerialActiveMessageC {
  provides {
    interface Init;
    interface Send;
    interface Receive;
  }
  uses interface Leds;
}
implementation { 
  components SerialPacketInfoActiveMessageC as Info, SerialDispatcherC;

  Init = SerialDispatcherC;
  Leds = SerialDispatcherC;
  Send = SerialDispatcherC.Send[TOS_SERIAL_ACTIVE_MESSAGE_ID];
  Receive = SerialDispatcherC.Receive[TOS_SERIAL_ACTIVE_MESSAGE_ID];
  SerialDispatcherC.SerialPacketInfo[TOS_SERIAL_ACTIVE_MESSAGE_ID] -> Info;
}
