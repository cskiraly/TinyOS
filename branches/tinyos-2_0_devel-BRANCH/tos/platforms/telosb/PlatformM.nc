includes hardware;

module PlatformM
{
  provides interface Init;
  uses interface Init as MSP430ClockInit;
}
implementation
{
  void disable_watchdog_timer()
  {
    WDTCTL = WDTPW | WDTHOLD;
  }

  command error_t Init.init()
  {
    disable_watchdog_timer();
    TOSH_SET_PIN_DIRECTIONS();
    call MSP430ClockInit.init();
    return SUCCESS;
  }
}

