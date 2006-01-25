#include "basicsb.h"

configuration PhotoDeviceArbiterP {
  provides {
    interface Read<uint16_t>[uint8_t client];
    interface ReadNow<uint16_t>[uint8_t client];
    interface ReadStream<uint16_t>[uint8_t client];
    interface Resource[uint8_t client];
  }
  uses {
    interface Read<uint16_t> as ActualRead[uint8_t client];
    interface ReadNow<uint16_t> as ActualReadNow[uint8_t client];
    interface ReadStream<uint16_t> as ActualReadStream[uint8_t client];
    interface Resource as ReadResource[uint8_t client];
    interface Resource as StreamResource[uint8_t client];
  }
}
implementation {
  components new ArbitratedReadC(uint16_t) as ArbitrateRead,
    new ArbitratedReadNowC(uint16_t) as ArbitrateReadNow,
    new ArbitratedReadStreamC(uniqueCount(UQ_TEMPDEVICE_STREAM), uint16_t) as ArbitrateReadStream,
    new RoundRobinArbiterC(UQ_TEMPDEVICE) as PhotoArbiter,
    new StdControlPowerManagerC() as PM,
    MainC, PhotoP, MicaBusC;

  Resource = PhotoArbiter;

  Read = ArbitrateRead;
  ActualRead = ArbitrateRead;
  ReadNow = ArbitrateReadNow;
  ActualReadNow = ArbitrateReadNow;
  ReadStream = ArbitrateReadStream;
  ActualReadStream = ArbitrateReadStream;

  ReadResource = ArbitrateRead;
  ReadResource = ArbitrateReadNow;
  StreamResource = ArbitrateReadStream;

  PM.Init <- MainC;
  PM.StdControl -> PhotoP;
  PM.ArbiterInit -> PhotoArbiter;
  PM.ResourceController -> PhotoArbiter;
  PM.ArbiterInfo -> PhotoArbiter;

  PhotoP.PhotoPin -> MicaBusC.PW1;
}
