/*
 * @author David Gay <dgay@intel-research.net>
 */

generic configuration AlarmMicro32C()
{
  provides interface Alarm<TMicro, uint32_t>;
}
implementation
{
  components new AlarmMicro16C() as Alarm16, CounterMicro32C as Counter32,
    new TransformAlarmC(TMicro, uint32_t, TMicro, uint16_t, 0)
      as Transform32;

  Alarm = Transform32;
  Transform32.AlarmFrom -> Alarm16;
  Transform32.Counter -> Counter32;
}
