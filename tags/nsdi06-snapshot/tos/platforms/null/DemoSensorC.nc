module DemoSensorC
{
  provides interface StdControl;	
  provides interface AcquireData;
}
implementation
{
  command error_t StdControl.start() {
    return SUCCESS;
  }

  command error_t StdControl.stop() {
    return SUCCESS;
  }

  command error_t AcquireData.getData() {
    return SUCCESS;
  }
}
