// $Id: BlinkC.nc,v 1.1.2.3 2005-04-22 06:15:38 cssharp Exp $

configuration BlinkC
{
}
implementation
{
  components Main, BlinkM, LedsC, new AlarmMilliC() as AlarmC;
  BlinkM.Boot -> Main;
  Main.SoftwareInit -> LedsC;
  Main.SoftwareInit -> AlarmC;
  BlinkM.Leds -> LedsC;
  BlinkM.Alarm -> AlarmC;
}

