module TimerMilliC
{
  provides interface Init;
  provides interface Timer<TMilli> as TimerMilli[ uint8_t num ];
}
implementation
{

  command error_t Init.init() {
    return SUCCESS;
  }

  command void TimerMilli.startPeriodic[ uint8_t num ]( uint32_t dt ) {
  }

  command void TimerMilli.startOneShot[ uint8_t num ]( uint32_t dt ) {
  }

  command void TimerMilli.stop[ uint8_t num ]() {
  }

  command bool TimerMilli.isRunning[ uint8_t num ]() {
    return FALSE;
  }

  command bool TimerMilli.isOneShot[ uint8_t num ]() {
    return FALSE;
  }

  command void TimerMilli.startPeriodicAt[ uint8_t num ]( uint32_t t0, uint32_t dt ) {
  }

  command void TimerMilli.startOneShotAt[ uint8_t num ]( uint32_t t0, uint32_t dt ) {
  }

  command uint32_t TimerMilli.getNow[ uint8_t num ]() {
    return 0;
  }

  command uint32_t TimerMilli.gett0[ uint8_t num ]() {
    return 0;
  }

  command uint32_t TimerMilli.getdt[ uint8_t num ]() {
    return 0;
  }
}
