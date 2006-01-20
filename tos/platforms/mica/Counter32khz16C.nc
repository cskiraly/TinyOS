/**
 * @author David Gay <dgay@intel-research.net>
 */

configuration Counter32khz16C
{
  provides interface Counter<T32khz, uint16_t>;
}
implementation
{
  components HplAtm128Timer3C as HWTimer, Init32khzP,
    new Atm128CounterC(T32khz, uint16_t) as NCounter;
  
  Counter = NCounter;
  NCounter.Timer -> HWTimer;
}
