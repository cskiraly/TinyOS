
generic module CastCounterM( typedef frequency_tag )
{
  provides interface Counter<frequency_tag> as Counter;
  uses interface CounterBase<uint32_t,frequency_tag> as CounterFrom;
}
implementation
{
  async command uint32_t Counter.get()
  {
    return call CounterFrom.get();
  }

  async command bool Counter.isOverflowPending()
  {
    return call CounterFrom.isOverflowPending();
  }

  async command void Counter.clearOverflow()
  {
    call CounterFrom.clearOverflow();
  }

  async event void CounterFrom.overflow()
  {
    signal Counter.overflow();
  }

  default async event void Counter.overflow()
  {
  }
}

