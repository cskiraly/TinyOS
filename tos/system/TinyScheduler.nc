
configuration TinyScheduler
{
  provides interface Scheduler;
  provides interface TaskBasic[uint8_t id];
}
implementation
{
  components SchedulerBasic;
  Scheduler = SchedulerBasic;
  TaskBasic = SchedulerBasic;
}

