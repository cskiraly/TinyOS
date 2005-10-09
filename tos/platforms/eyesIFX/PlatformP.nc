includes hardware;

module PlatformP{
  provides interface Init;
  uses interface Init as MSP430ClockInit;
}
implementation {
  command error_t Init.init() {
    call MSP430ClockInit.init();
    TOSH_SET_PIN_DIRECTIONS();
    return SUCCESS;
  }
}

