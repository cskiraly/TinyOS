/*
 * @author David Gay <dgay@intel-research.net>
 * @author Martin Turon <mturon@xbow.com>
 */

configuration AlarmCounterMilliP
{
  provides interface Init;
  provides interface Alarm<TMilli, uint32_t> as AlarmMilli32;
  provides interface Counter<TMilli, uint32_t> as CounterMilli32;
}
implementation
{
  components HplAtm128Timer0AsyncC as Timer0, PlatformC,
    new Atm128AlarmC(TMilli, uint8_t, ATM128_CLK8_DIVIDE_32, 2) as MilliAlarm,
    new Atm128CounterC(TMilli, uint8_t) as MilliCounter, 
    new TransformAlarmCounterC(TMilli, uint32_t, TMilli, uint8_t, 0, uint32_t)
      as Transform32;

  // Top-level interface wiring
  AlarmMilli32 = Transform32;
  CounterMilli32 = Transform32;

  // Strap in low-level hardware timer (Timer0Async)
  Init = MilliAlarm;
  MilliAlarm.HplAtm128Timer -> Timer0.Timer0;
  MilliAlarm.HplAtm128Compare -> Timer0.Compare0;
  MilliCounter.Timer -> Timer0.Timer0;
  PlatformC.SubInit -> Timer0;

  // Alarm Transform Wiring
  Transform32.AlarmFrom -> MilliAlarm;
  Transform32.CounterFrom -> MilliCounter;
}
