/**
 * @author David Gay <dgay@intel-research.net>
 */

#include "Atm128Timer.h"

generic configuration AlarmMicro16C()
{
  provides interface Alarm<TMicro, uint16_t>;
}
implementation
{
  components HplAtm128Timer3C as HWTimer, InitMicroP,
    new Atm128AlarmC(TMicro, uint16_t, 100) as NAlarm;
  
  enum {
    COMPARE_ID = unique(UQ_TIMER3_COMPARE)
  };

  Alarm = NAlarm;

  NAlarm.HplAtm128Timer -> HWTimer.Timer;
  NAlarm.HplAtm128Compare -> HWTimer.Compare[COMPARE_ID];
}
