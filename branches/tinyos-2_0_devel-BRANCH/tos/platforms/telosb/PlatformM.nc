includes hardware;

module PlatformM
{
  provides interface Init;
  uses interface Init as MSP430ClockInit;
}
implementation
{
  command error_t Init.init()
  {
    TOSH_SET_PIN_DIRECTIONS();
    call MSP430ClockInit.init();
    return SUCCESS;
  }
}

