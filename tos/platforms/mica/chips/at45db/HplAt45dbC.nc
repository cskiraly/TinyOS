configuration HplAt45dbC {
  provides interface HplAt45db @atmostonce();
}
implementation {
  components new HplAt45dbByteC(), HplAt45dbIOC;

  HplAt45db = HplAt45dbByteC;

  HplAt45dbByteC.FlashSPI -> HplAt45dbIOC;
  HplAt45dbByteC.HplAt45dbIO -> HplAt45dbIOC;
}
