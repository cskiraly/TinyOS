
generic module CastCounter32( typename frequency_tag )
{
  provides interface Counter32<frequency_tag> as Counter;
  uses interface Counter<uint32_t,frequency_tag> as CounterFrom;
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

  async command bool Counter.clearOverflow()
  {
    return call CounterFrom.clearOverflow();
  }

  async event void Counter.overflow()
  {
    return call CounterFrom.overflow();
  }
}

