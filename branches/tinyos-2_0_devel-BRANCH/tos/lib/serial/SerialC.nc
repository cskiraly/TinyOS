configuration SerialC {
  provides {
    interface Init;
    interface Receive;
    interface Send;
  }
}
implementation {
  components SerialM, PlatformSerial, LedsC;
  components TinyScheduler;

  Init = SerialM;
  Receive = SerialM;
  Send = SerialM;

  SerialM.SerialByteComm -> PlatformSerial;
  SerialM.PacketRcvd -> TinyScheduler.TaskBasic[unique("TinyScheduler.TaskBasic")];
  SerialM.PacketSent -> TinyScheduler.TaskBasic[unique("TinyScheduler.TaskBasic")];

  SerialM.Leds -> LedsC;
}

