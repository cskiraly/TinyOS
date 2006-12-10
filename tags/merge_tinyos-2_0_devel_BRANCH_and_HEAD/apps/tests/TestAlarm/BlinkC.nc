// $Id: BlinkC.nc,v 1.1.2.3 2006-11-07 23:14:51 scipio Exp $

configuration BlinkC
{
}
implementation
{
  components MainC, BlinkM, LedsC, new AlarmMilliC() as AlarmC;
  BlinkM.Boot -> MainC;
  
  MainC.SoftwareInit -> AlarmC;
  BlinkM.Leds -> LedsC;
  BlinkM.Alarm -> AlarmC;
}

