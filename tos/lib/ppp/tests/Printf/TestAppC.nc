configuration TestAppC {
} implementation {
  components TestP;

  components MainC;
  TestP.Boot -> MainC;

  components PppC;
  TestP.PppControl -> PppC;

  components PlatformSerialC;
  PppC.UartStream -> PlatformSerialC;
  PppC.UartControl -> PlatformSerialC;

  components PppPrintfC;
  PppC.PppProtocol[PppPrintfC.Protocol] -> PppPrintfC;
  PppPrintfC.Ppp -> PppC;

  components LedC;
#if DEBUG_PppPrintf
  components SerialPrintfC;
#endif

}


