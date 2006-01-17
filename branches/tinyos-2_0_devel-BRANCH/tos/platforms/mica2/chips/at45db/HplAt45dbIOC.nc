configuration HplAt45dbIOC {
  provides {
    interface SPIByte as FlashSpi;
    interface HplAt45dbByte;
  }
}
implementation {
  // Wire up byte I/O to At45db
  components HplAt45dbIOP, HplAtm128GeneralIOC as Pins, HplAtm128InterruptC, PlatformC;
  components BusyWaitMicroC;

  FlashSpi = HplAt45dbIOP;
  HplAt45dbByte = HplAt45dbIOP;

  PlatformC.SubInit -> HplAt45dbIOP;
  HplAt45dbIOP.Select -> Pins.PortA3;
  HplAt45dbIOP.Clk -> Pins.PortD5;
  HplAt45dbIOP.In -> Pins.PortD2;
  HplAt45dbIOP.Out -> Pins.PortD3;
  HplAt45dbIOP.InInterrupt -> HplAtm128InterruptC.Int2;
  HplAt45dbIOP.BusyWait -> BusyWaitMicroC;
}
