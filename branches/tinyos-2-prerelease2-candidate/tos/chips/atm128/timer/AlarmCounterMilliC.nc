/*
 * @author David Gay <dgay@intel-research.net>
 * @author Martin Turon <mturon@xbow.com>
 */

configuration AlarmCounterMilliC
{
  provides interface Init;
  provides interface Alarm<TMilli, uint32_t> as AlarmMilli32;
  provides interface Counter<TMilli, uint32_t> as CounterMilli32;
  provides interface LocalTime<TMilli> as LocalTimeMilli;
}
implementation
{
  components HplTimer0AsyncC,
    new Atm128AlarmC(TMilli, uint8_t, ATM128_CLK8_DIVIDE_32, 2) as MilliAlarm,
    new Atm128CounterC(TMilli, uint8_t) as MilliCounter, 
    new TransformAlarmCounterC(TMilli, uint32_t, TMilli, uint8_t, 0, uint32_t)
      as Transform32,
    new CounterToLocalTimeC(TMilli);

  // Top-level interface wiring
  AlarmMilli32 = Transform32;
  CounterMilli32 = Transform32;
  LocalTimeMilli = CounterToLocalTimeC;

  // Strap in low-level hardware timer (Timer0Async)
  Init = MilliAlarm;
  MilliAlarm.HplTimer -> HplTimer0AsyncC.Timer0;
  MilliAlarm.HplCompare -> HplTimer0AsyncC.Compare0;
  MilliCounter.Timer -> HplTimer0AsyncC.Timer0;

  // Alarm Transform Wiring
  Transform32.AlarmFrom -> MilliAlarm;
  Transform32.CounterFrom -> MilliCounter;
  CounterToLocalTimeC.Counter -> Transform32;
}
