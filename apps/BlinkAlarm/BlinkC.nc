// $Id: BlinkC.nc,v 1.1.2.1 2005-02-11 02:20:01 cssharp Exp $

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
  BlinkM.Alarm -> AlarmC.AlarmTimer32khz;
}

