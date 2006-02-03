// $Id: BlinkC.nc,v 1.1.2.1 2006-02-03 19:42:46 idgay Exp $

configuration BlinkC
{
}
implementation
{
  components MainC as Main, BlinkM, LedsC, MSP430TimerC;
  BlinkM.Boot -> Main;
  Main.SoftwareInit -> LedsC;
  BlinkM.Leds -> LedsC;
  BlinkM.TimerControl -> MSP430TimerC.ControlB4;
  BlinkM.TimerCompare -> MSP430TimerC.CompareB4;
}

