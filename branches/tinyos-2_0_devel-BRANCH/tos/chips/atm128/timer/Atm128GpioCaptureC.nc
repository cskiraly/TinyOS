
generic module Atm128GpioCaptureC() {

  provides interface GpioCapture as Capture;
  uses interface HplAtm128Capture<uint16_t> as Atm128Capture;

}

implementation {

  error_t enableCapture( uint8_t mode ) {
    atomic {
      call Atm128Capture.stop();
      call Atm128Capture.reset();
      call Atm128Capture.setEdge( mode );
      call Atm128Capture.start();
    }
    return SUCCESS;
  }

  async command error_t Capture.captureRisingEdge() {
    return enableCapture( TRUE );
  }

  async command error_t Capture.captureFallingEdge() {
    return enableCapture( FALSE );
  }

  async command void Capture.disable() {
    call Atm128Capture.stop();
  }

  async event void Atm128Capture.captured( uint16_t time ) {
    call Atm128Capture.reset();
    signal Capture.captured( time );
  }

}
