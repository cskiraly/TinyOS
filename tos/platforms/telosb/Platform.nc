includes hardware;

configuration Platform
{
  provides interface Init;
}
implementation
{
  components PlatformM, MSP430ClockC;

  Init = PlatformM;
  PlatformM.MSP430ClockInit -> MSP430ClockC.Init;
}

