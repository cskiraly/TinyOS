configuration PlatformSerialC {
  provides interface Init;
  provides interface StdControl;
  provides interface SerialByteComm;
}
implementation {
  components HPLUARTM, HPLUSART1C;

  Init = HPLUARTM;
  StdControl = HPLUARTM;
  SerialByteComm = HPLUARTM;

  HPLUARTM.USARTControl -> HPLUSART1C;
  HPLUARTM.USARTData -> HPLUSART1C;
}
