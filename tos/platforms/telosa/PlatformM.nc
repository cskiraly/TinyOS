includes hardware;

module PlatformM
{
  provides interface Init;
  uses interface Init as MSP430ClockInit;
  uses interface Init as HPLUSART1Init;
}
implementation
{
  command error_t Init.init()
  {
    call MSP430ClockInit.init();
    TOSH_SET_PIN_DIRECTIONS();
    call HPLUSART1Init.init();
    return SUCCESS;
  }
}

