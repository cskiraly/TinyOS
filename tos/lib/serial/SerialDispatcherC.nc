configuration SerialDispatcherC {
  provides {
    interface Init;
    interface Receive[uart_id_t];
    interface Send[uart_id_t];
  }
  uses {
    interface SerialPacketInfo[uart_id_t];
  }
}
implementation {
  components SerialM, SerialDispatcherM, HldcTranslateM as HdlcTranslateM, 
    HPLUARTM, LedsC;
  
  Send = SerialDispatcherM;
  Receive = SerialDispatcherM;
  SerialPacketInfo = SerialDispatcherM;
  
  Init = SerialM;
  Init = HPLUARTM.UART0Init;

  SerialDispatcherM.ReceiveBytePacket = SerialM;
  SerialDispatcherM.SendBytePacket = SerialM;

  SerialM.SerialFrameComm -> HdlcTranslateM;
  HdlcTranslateM.SerialByteComm -> HPLUARTM.UART0;
  
}
