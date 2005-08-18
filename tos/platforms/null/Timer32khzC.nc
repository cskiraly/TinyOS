module Timer32khzC
{
  provides interface Init;
  provides interface Timer<T32khz> as Timer32khz[ uint8_t num ];
}
implementation
{

  command error_t Init.init() {
    return SUCCESS;
  }

  command void Timer32khz.startPeriodicNow[ uint8_t num ]( uint32_t dt ) {
  }

  command void Timer32khz.startOneShotNow[ uint8_t num ]( uint32_t dt ) {
  }

  command void Timer32khz.stop[ uint8_t num ]() {
  }

  command bool Timer32khz.isRunning[ uint8_t num ]() {
    return FALSE;
  }

  command bool Timer32khz.isOneShot[ uint8_t num ]() {
    return FALSE;
  }

  command void Timer32khz.startPeriodic[ uint8_t num ]( uint32_t t0, uint32_t dt ) {
  }

  command void Timer32khz.startOneShot[ uint8_t num ]( uint32_t t0, uint32_t dt ) {
  }

  command uint32_t Timer32khz.getNow[ uint8_t num ]() {
    return 0;
  }

  command uint32_t Timer32khz.gett0[ uint8_t num ]() {
    return 0;
  }

  command uint32_t Timer32khz.getdt[ uint8_t num ]() {
    return 0;
  }
}
