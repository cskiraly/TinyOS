configuration SerialC {
  provides {
    interface Init;
    interface Receive[uart_id_t];
    interface Send[uart_id_t];
  }
}
implementation {
  components SerialM, 
             SerialDispatcherM,
             HldcTranslateM as HDLCTranslateM,
             LedsC;

  
  Send = SerialDispatcherM;
  Receive = SerialDispatcherM;





  Init = SerialM;
  Receive = SerialM;
  Send = SerialM;
  Packet = SerialM;

  SerialM.SerialByteComm -> PlatformSerial;
  SerialM.PacketRcvd -> TinyScheduler.TaskBasic[unique("TinyScheduler.TaskBasic")];
  SerialM.PacketSent -> TinyScheduler.TaskBasic[unique("TinyScheduler.TaskBasic")];

  SerialM.Leds -> LedsC;
}

