configuration HPLCC1000InitC {
  provides interface Init as PlatformInit;
}
implementation {
  components HPLCC1000P, HPLCC1000SpiC, HPLGeneralIOC as IO;

  PlatformInit = HPLCC1000P;
  PlatformInit = HPLCC1000SpiC;

  HPLCC1000P.CHP_OUT -> IO.PortA6;
  HPLCC1000P.PALE -> IO.PortD4;
  HPLCC1000P.PCLK -> IO.PortD6;
  HPLCC1000P.PDATA -> IO.PortD7;

  HPLCC1000SpiC.SpiSck -> IO.PortB1;
  HPLCC1000SpiC.SpiMiso -> IO.PortB3;
  HPLCC1000SpiC.SpiMosi -> IO.PortB2;
  HPLCC1000SpiC.OC1C -> IO.PortB7;
}
