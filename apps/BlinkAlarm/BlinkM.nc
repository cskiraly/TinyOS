// $Id: BlinkM.nc,v 1.1.2.2 2005-02-26 02:34:35 cssharp Exp $

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
      call Leds.greenOn();
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
      call Leds.redToggle();
    }
  }
}

