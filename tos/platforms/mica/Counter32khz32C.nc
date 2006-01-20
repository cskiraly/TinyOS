/*
 * @author David Gay <dgay@intel-research.net>
 */

configuration Counter32khz32C
{
  provides interface Counter<T32khz, uint32_t>;
}
implementation
{
  components Counter32khz16C as Counter16, 
    new TransformCounterC(T32khz, uint32_t, T32khz, uint16_t, 0, uint16_t)
      as Transform32;

  Counter = Transform32;
  Transform32.CounterFrom -> Counter16;
}
