/**
 * @author David Gay <dgay@intel-research.net>
 */

generic configuration Alarm32khz16C()
{
  provides interface Alarm<T32khz, uint16_t>;
}
implementation
{
  components HplAtm128Timer1C as HWTimer, Init32khzP,
    new Atm128AlarmC(T32khz, uint16_t, 2) as NAlarm;
  
  enum {
    COMPARE_ID = unique(UQ_TIMER1_COMPARE)
  };

  Alarm = NAlarm;

  NAlarm.HplAtm128Timer -> HWTimer.Timer;
  NAlarm.HplAtm128Compare -> HWTimer.Compare[COMPARE_ID];
}
