#include <sys/time.h>

module HilTimerMilliP;
{
  provides interface Init;
  provides interface LocalTime<TMilli>;
}
implementation
{
  struct timeval boot_time;

  command error_t Init.init() {
    gettimeofday(&boot_time, NULL);
    return SUCCESS;
  }

  async command uint32_t LocalTime.get() {
    struct timeval now, diff;
    uint32_t tics_now;
    gettimeofday(&now, NULL);
    timersub(&now, &boot_time, &diff);

    tics_now = (diff.tv_usec * 1024) / 1e6;
    tics_now += diff.tv_sec * 1024;

    return tics_now;
  }
}
