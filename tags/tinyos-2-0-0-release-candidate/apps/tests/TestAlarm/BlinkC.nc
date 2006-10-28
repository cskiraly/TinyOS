// $Id: BlinkC.nc,v 1.1.2.2 2006-02-04 01:10:33 philipb Exp $

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

