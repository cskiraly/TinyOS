// $Id: BlinkC.nc,v 1.1.2.1 2005-02-09 00:33:12 cssharp Exp $

configuration BlinkC
{
}
implementation
{
  components Main, BlinkM, LedsC, MSP430TimerC;
  BlinkM.Boot -> Main;
  Main.SoftwareInit -> LedsC;
  BlinkM.Leds -> LedsC;
  BlinkM.TimerControl -> MSP430TimerC.ControlB4;
  BlinkM.TimerCompare -> MSP430TimerC.CompareB4;
}

