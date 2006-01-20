/*
 * @author David Gay <dgay@intel-research.net>
 */

generic configuration Alarm32khz32C()
{
  provides interface Alarm<T32khz, uint32_t>;
}
implementation
{
  components new Alarm32khz16C() as Alarm16, Counter32khz32C as Counter32,
    new TransformAlarmC(T32khz, uint32_t, T32khz, uint16_t, 0)
      as Transform32;

  Alarm = Transform32;
  Transform32.AlarmFrom -> Alarm16;
  Transform32.Counter -> Counter32;
}
