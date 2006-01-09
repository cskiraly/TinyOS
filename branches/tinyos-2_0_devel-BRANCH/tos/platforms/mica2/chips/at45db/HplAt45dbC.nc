configuration HplAt45dbC {
  provides interface HplAt45db;
}
implementation {
  // Wire up byte I/O to At45db
  components HplAt45dbIOP, HplGeneralIOC as Pins, HplInterruptC, PlatformC;

  PlatformC.SubInit -> HplAt45dbIOP;
  HplAt45dbIOP.Select -> Pins.PortA3;
  HplAt45dbIOP.Clk -> Pins.PortD5;
  HplAt45dbIOP.In -> Pins.PortD2;
  HplAt45dbIOP.Out -> Pins.PortD3;
  HplAt45dbIOP.InInterrupt -> HplInterruptC.Int2;

  // And make it into an HPL
  components new HplAt45dbByteC();

  HplAt45db = HplAt45dbByteC;
  HplAt45dbByteC.FlashSpi -> HplAt45dbIOP;
  HplAt45dbByteC.HplAt45dbByte -> HplAt45dbIOP;
}
