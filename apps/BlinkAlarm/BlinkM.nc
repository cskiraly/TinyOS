// $Id: BlinkM.nc,v 1.1.2.3 2005-03-19 20:59:14 scipio Exp $

includes Timer;

module BlinkM
{
  uses interface Boot;
  uses interface Leds;
  uses interface Alarm<TMilli> as Alarm;
}
implementation
{
  uint32_t m_t0;
  enum { DELAY_MILLI = 512 };

  event void Boot.booted()
  {
    atomic
    {
      call Leds.led2On();
      m_t0 = call Alarm.now();
      call Alarm.set( m_t0, DELAY_MILLI );
    }
  }

  async event void Alarm.fired()
  {
    atomic
    {
      // this use of m_t0 produces a periodic alarm with no frequency skew
      m_t0 += DELAY_MILLI;
      call Alarm.set( m_t0, DELAY_MILLI );
      call Leds.led1Toggle();
    }
  }
}

