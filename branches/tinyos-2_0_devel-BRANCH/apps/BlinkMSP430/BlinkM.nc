// $Id: BlinkM.nc,v 1.1.2.1 2005-02-09 00:33:12 cssharp Exp $

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
  }

  async event void TimerCompare.fired()
  {
    call TimerCompare.setEventFromPrev( 8192 );
    call Leds.redToggle();
  }
}


