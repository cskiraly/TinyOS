// $Id: BlinkC.nc,v 1.1.2.2 2005-02-26 02:34:35 cssharp Exp $

configuration BlinkC
{
}
implementation
{
  components Main, BlinkM, LedsC, AlarmC;
  BlinkM.Boot -> Main;
  Main.SoftwareInit -> LedsC;
  Main.SoftwareInit -> AlarmC;
  BlinkM.Leds -> LedsC;
  BlinkM.Alarm -> AlarmC.AlarmTimerMilli;
}

