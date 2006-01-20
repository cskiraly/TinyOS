/**
 * @author David Gay <dgay@intel-research.net>
 */

configuration CounterMicro16C
{
  provides interface Counter<TMicro, uint16_t>;
}
implementation
{
  components HplAtm128Timer3C as HWTimer, InitMicroP,
    new Atm128CounterC(TMicro, uint16_t) as NCounter;
  
  Counter = NCounter;
  NCounter.HplAtm128Timer -> HWTimer.Timer;
}
