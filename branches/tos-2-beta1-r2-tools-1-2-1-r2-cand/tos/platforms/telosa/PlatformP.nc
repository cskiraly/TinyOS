includes hardware;

module PlatformP{
  provides interface Init;
  uses interface Init as Msp430ClockInit;
  uses interface Init as LedsInit;
  uses interface Init as InitL1;
  uses interface Init as InitL2;
  uses interface Init as InitL3;
}
implementation {
  command error_t Init.init() {
    call Msp430ClockInit.init();
    TOSH_SET_PIN_DIRECTIONS();
    call LedsInit.init();
    return SUCCESS;
  }

  default command error_t LedsInit.init() { return SUCCESS; }

}

