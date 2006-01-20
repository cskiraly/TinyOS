/*
 * @author David Gay <dgay@intel-research.net>
 */

configuration CounterMicro32C
{
  provides interface Counter<TMicro, uint32_t>;
}
implementation
{
  components CounterMicro16C as Counter16, 
    new TransformCounterC(TMicro, uint32_t, TMicro, uint16_t, 0, uint16_t)
      as Transform32;

  Counter = Transform32;
  Transform32.CounterFrom -> Counter16;
}
