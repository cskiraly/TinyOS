
interface PXA27XOSTimer
{
  async event void fired();
}


module PXA27XOSTimerM.nc {
  provides interface PXA27XOSTimer;
  uses interface PXA27XInterrupt as OSTimerIrq;
}

implementation {

}
  
