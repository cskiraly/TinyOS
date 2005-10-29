includes msp430baudrates;

generic module Msp430UartP() {

  provides interface Init;
  provides interface StdControl;
  provides interface SerialByteComm;
  
  uses interface HplMsp430Usart as HplUsart;
}

implementation {

  command error_t Init.init() {
    return SUCCESS;
  }

  command error_t StdControl.start() {
    call HplUsart.setModeUART();
    call HplUsart.setClockSource(SSEL_SMCLK);
    call HplUsart.setClockRate(UBR_SMCLK_57600, UMCTL_SMCLK_57600);

    call HplUsart.enableRxIntr();
    call HplUsart.enableTxIntr();
    return SUCCESS;
  }

  command error_t StdControl.stop() {
    call HplUsart.disableRxIntr();
    call HplUsart.disableTxIntr();

    call HplUsart.disableUART();
    return SUCCESS;
  }

  async command error_t SerialByteComm.put( uint8_t data ) {
    call HplUsart.tx( data );
    return SUCCESS;
  }

  async event void HplUsart.txDone() {
    signal SerialByteComm.putDone();
  }

  async event void HplUsart.rxDone( uint8_t data ) {
    signal SerialByteComm.get( data );
  }
}
