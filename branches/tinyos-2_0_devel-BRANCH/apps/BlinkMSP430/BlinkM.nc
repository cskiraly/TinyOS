// $Id: BlinkM.nc,v 1.1.2.2 2005-02-10 00:59:56 cssharp Exp $

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
    call Leds.greenOn();
    call TimerControl.setControlAsCompare();
    call TimerCompare.setEventFromNow( 8192 );
    call TimerControl.enableEvents();
  }

  async event void TimerCompare.fired()
  {
    call Leds.redToggle();
    call TimerCompare.setEventFromPrev( 8192 );
  }
}

