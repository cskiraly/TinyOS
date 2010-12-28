#include "sam3upmchardware.h"

module RadioControlP{
  provides interface SplitControl as HighRadioControl;
  uses interface SplitControl as LowRadioControl;
  uses interface HplSam3uTC as TC;
}
implementation{
  command error_t HighRadioControl.start(){
    // start TC0
    call TC.enableTC0();
    //PMC->pcer.bits.spi0 = 1;
    return call LowRadioControl.start();
  }

  command error_t HighRadioControl.stop(){
    // stop TC0 
    call TC.disableTC0();
    return call LowRadioControl.stop();
  }

  event void LowRadioControl.startDone(error_t error){
    signal HighRadioControl.startDone(error);
  }
  
  event void LowRadioControl.stopDone(error_t error) {
    signal HighRadioControl.stopDone(error);
  }

 default event void HighRadioControl.startDone(error_t error) {}
  
 default event void HighRadioControl.stopDone(error_t error) {}

}