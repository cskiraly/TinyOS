

configuration HilTimerMilliC
{
  provides interface Init;
  provides interface Timer<TMilli> as TimerMilli[ uint8_t num ];
  provides interface LocalTime<TMilli>;
} implementation  {

  components HilAlarmMilliP;

  components new AlarmToTimerC(TMilli), new VirtualizeTimerC(TMilli, 255);

  Init = HilAlarmMilliP;
  LocalTime = HilAlarmMilliP;

  AlarmToTimerC.Alarm -> HilAlarmMilliP;
  VirtualizeTimerC.TimerFrom -> AlarmToTimerC;
  TimerMilli = VirtualizeTimerC.Timer;

}
