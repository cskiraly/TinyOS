includes hardware;

module PlatformP{
  provides interface Init;
  uses interface Init as Msp430ClockInit;
}
implementation {
  command error_t Init.init() {
    call Msp430ClockInit.init();
    TOSH_SET_PIN_DIRECTIONS();
    return SUCCESS;
  }
}

