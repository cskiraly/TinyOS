configuration HPLCC1000InitC {
  provides interface Init as PlatformInit;
}
implementation {
  components HPLCC1000M, HPLCC1000SpiM, HPLGeneralIO as IO;

  PlatformInit = HPLCC1000M;
  PlatformInit = HPLCC1000SpiM;

  HPLCC1000M.CHP_OUT -> IO.PortA6;
  HPLCC1000M.PALE -> IO.PortD4;
  HPLCC1000M.PCLK -> IO.PortD6;
  HPLCC1000M.PDATA -> IO.PortD7;

  HPLCC1000SpiM.SpiSck -> IO.PortB1;
  HPLCC1000SpiM.SpiMiso -> IO.PortB3;
  HPLCC1000SpiM.SpiMosi -> IO.PortB2;
  HPLCC1000SpiM.OC1C -> IO.PortB7;
}
