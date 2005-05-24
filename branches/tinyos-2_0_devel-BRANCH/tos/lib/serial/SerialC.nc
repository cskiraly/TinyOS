configuration SerialC {
  provides {
    interface Init;
    interface Receive;
    interface Send;
    interface Packet;    
  }
}
implementation {
  components SerialM, PlatformSerial, LedsC;
  components TinyScheduler;

  Init = SerialM;
  Receive = SerialM;
  Send = SerialM;
  Packet = SerialM;

  SerialM.SerialByteComm -> PlatformSerial;
  SerialM.PacketRcvd -> TinyScheduler.TaskBasic[unique("TinyScheduler.TaskBasic")];
  SerialM.PacketSent -> TinyScheduler.TaskBasic[unique("TinyScheduler.TaskBasic")];

  SerialM.Leds -> LedsC;
}

