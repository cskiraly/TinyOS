// $Id: BlinkM.nc,v 1.1.2.2 2006-11-07 23:14:53 scipio Exp $

module BlinkM
{
  uses interface MSP430TimerControl as TimerControl;
  uses interface MSP430Compare as TimerCompare;
  uses interface Boot;
  uses interface Leds;
}
implementation
{
  event void Boot.booted()
  {
    call Leds.led1On();
    call TimerControl.setControlAsCompare();
    call TimerCompare.setEventFromNow( 8192 );
    call TimerControl.enableEvents();
  }

  async event void TimerCompare.fired()
  {
    call Leds.led0Toggle();
    call TimerCompare.setEventFromPrev( 8192 );
  }
}

