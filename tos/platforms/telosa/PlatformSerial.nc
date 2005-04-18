configuration PlatformSerial {
  provides interface HPLUART as SerialByteComm;
}
implementation {
  components HPLUARTM, HPLUSART1C;

  SerialByteComm = HPLUARTM;

  HPLUARTM.USARTControl -> HPLUSART1C;
  HPLUARTM.USARTData -> HPLUSART1C;
}
