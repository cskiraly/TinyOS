// $Id: BlinkM.nc,v 1.1.2.1 2005-02-11 02:20:01 cssharp Exp $

includes Timer;

module BlinkM
{
  uses interface Boot;
  uses interface Leds;
  uses interface Alarm<T32khz> as Alarm;
}
implementation
{
  uint32_t m_t0;
  enum { DELAY_32MICRO = 8192 };

  event void Boot.booted()
  {
    atomic
    {
      call Leds.greenOn();
      m_t0 = call Alarm.now();
      call Alarm.set( m_t0, DELAY_32MICRO );
    }
  }

  async event void Alarm.fired()
  {
    atomic
    {
      // this use of m_t0 produces a periodic alarm with no frequency skew
      m_t0 += DELAY_32MICRO;
      call Alarm.set( m_t0, DELAY_32MICRO );
      call Leds.redToggle();
    }
  }
}

