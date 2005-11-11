// $Id: BlinkC.nc,v 1.1.2.4 2005-11-11 02:28:13 philipb Exp $

configuration BlinkC
{
}
implementation
{
  components MainC, BlinkM, LedsC, new AlarmMilliC() as AlarmC;
  BlinkM.Boot -> MainC;
  MainC.SoftwareInit -> LedsC;
  MainC.SoftwareInit -> AlarmC;
  BlinkM.Leds -> LedsC;
  BlinkM.Alarm -> AlarmC;
}

