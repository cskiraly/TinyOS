
configuration TinyScheduler
{
  provides interface Scheduler;
  provides interface TaskBasic[uint8_t id];
}
implementation
{
  components SchedulerTemp as Sched;
  Scheduler = Sched;
  TaskBasic = Sched;
}

