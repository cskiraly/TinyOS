
generic module CastAlarmM( typedef frequency_tag )
{
  provides interface Alarm<frequency_tag> as Alarm;
  uses interface AlarmBase<uint32_t,frequency_tag> as AlarmFrom;
}
implementation
{
  async command uint32_t Alarm.now()
  {
    return call AlarmFrom.now();
  }

  async command uint32_t Alarm.get()
  {
    return call AlarmFrom.get();
  }

  async command bool Alarm.isSet()
  {
    return call AlarmFrom.isSet();
  }

  async command void Alarm.cancel()
  {
    return call AlarmFrom.cancel();
  }

  async command void Alarm.set( uint32_t t0, uint32_t dt )
  {
    return call AlarmFrom.set(t0,dt);
  }

  async event void AlarmFrom.fired()
  {
    signal Alarm.fired();
  }

  default async event void Alarm.fired()
  {
  }
}

