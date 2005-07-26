configuration SerialDispatcherC {
  provides {
    interface Init;
    interface Receive[uart_id_t];
    interface Send[uart_id_t];
  }
  uses {
    interface SerialPacketInfo[uart_id_t];
    interface Leds;
  }
}
implementation {
  components SerialM, new SerialDispatcherM(), 
    HdlcTranslateM, 
    HPLUARTM;
  
  Send = SerialDispatcherM;
  Receive = SerialDispatcherM;
  SerialPacketInfo = SerialDispatcherM.PacketInfo;
  
  Init = SerialM;
  Init = HPLUARTM.UART0Init;
  Leds = SerialM;

  SerialDispatcherM.ReceiveBytePacket -> SerialM;
  SerialDispatcherM.SendBytePacket -> SerialM;

  SerialM.SerialFrameComm -> HdlcTranslateM;
  HdlcTranslateM.SerialByteComm -> HPLUARTM.UART0;
  
}
