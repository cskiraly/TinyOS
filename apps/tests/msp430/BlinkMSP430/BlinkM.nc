// $Id: BlinkM.nc,v 1.1.2.1 2006-02-03 19:42:46 idgay Exp $

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

