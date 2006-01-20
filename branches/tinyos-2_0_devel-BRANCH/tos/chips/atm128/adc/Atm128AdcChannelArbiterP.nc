configuration Atm128AdcChannelArbiterP {
  provides {
    interface Read<uint16_t>[uint8_t client];
    interface ReadNow<uint16_t>[uint8_t client];
  }
  uses {
    interface Read<uint16_t> as ActualRead[uint8_t client];
    interface ReadNow<uint16_t> as ActualReadNow[uint8_t client];
    interface Resource[uint8_t client];
  }
}
implementation {
  components new ArbitratedReadC(uint16_t) as ReadArbiter,
    new ArbitratedReadNowC(uint16_t) as ReadNowArbiter;
  components AdcC;

  Read = ReadArbiter;
  ActualRead = ReadArbiter;
  ReadNow = ReadNowArbiter;
  ActualReadNow = ReadNowArbiter;
  Resource = ReadArbiter;
  Resource = ReadNowArbiter;
}
