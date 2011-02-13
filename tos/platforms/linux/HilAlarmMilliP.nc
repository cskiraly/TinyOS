#include <signal.h>
#include <sys/time.h>

struct timeval boot_time;

module HilAlarmMilliP {
  provides interface Init;
  provides interface Alarm<TMilli, uint32_t>;
  provides interface LocalTime<TMilli>;
} implementation {

  void sigalrm_fired(int sig) {
    dbg("HilAlarmMilliP", "ALARM\n");
    // run with other interrupts disabled jics.
    __nesc_disable_interrupt();
    signal Alarm.fired();
    __nesc_enable_interrupt();
  }

  command error_t Init.init() {
    struct sigaction s;
    gettimeofday(&boot_time, NULL);

    // block all other signals while handling the timer interrupt
    sigfillset(&s.sa_mask);
    s.sa_handler = sigalrm_fired;
    if (sigaction(SIGALRM, &s, NULL) < 0) {
      perror("sigaction");
    }

    return SUCCESS;
  }

  async command uint32_t LocalTime.get() {
    struct timeval now, diff;
    uint32_t tics_now;
    gettimeofday(&now, NULL);
    timersub(&now, &boot_time, &diff);

    tics_now = (diff.tv_usec * 1024) / 1e6;
    tics_now += diff.tv_sec * 1024;

    dbg("HilAlarmMilliP", "LOCALTIME: %u (%u.%.06u)\n", tics_now, diff.tv_sec, diff.tv_usec);
    
    return tics_now;
  }

  async command void Alarm.start(uint32_t dt) {
    struct itimerval v;
    if (dt == 0) dt++;
    dbg("HilAlarmMilliP", "ALARM START: %u\n", dt);

    timerclear(&v.it_interval);
    v.it_value.tv_sec  = dt / 1024;
    v.it_value.tv_usec = ((dt % 1024) * 1e6) / 1024;

    dbg("HilAlarmMilliP", "ITIMER: (%i.%.06i)\n", v.it_value.tv_sec, v.it_value.tv_usec);

    setitimer(ITIMER_REAL, &v, NULL);
  }

  async command void Alarm.stop() {
    struct itimerval v;
    timerclear(&v.it_interval);
    timerclear(&v.it_value);
    setitimer(ITIMER_REAL, &v, NULL);

    dbg("HilAlarmMilliP", "ALARM STOP\n");
  }
  async command bool Alarm.isRunning() {
    struct itimerval v;
    getitimer(ITIMER_REAL, &v);
    dbg("HilAlarmMilliP", "ALARM ISRUNNING\n");

    return (v.it_value.tv_sec == 0) && (v.it_value.tv_usec == 0);
  }

  async command void Alarm.startAt(uint32_t t0, uint32_t dt) {
    uint32_t real_dt = (call LocalTime.get()) - t0 + dt;
    dbg("HilAlarmMilliP", "ALARM STARTAT: (%u, %u)\n", t0, dt);
    dbg("HilAlarmMilliP", "real_dt: %u\n", real_dt);

    call Alarm.start(real_dt);
  }

  async command uint32_t Alarm.getNow() {
    return call LocalTime.get();
  }

  async command uint32_t Alarm.getAlarm() {
    struct itimerval v;
    getitimer(ITIMER_REAL, &v);
    dbg("HilAlarmMilliP", "ALARM GETALARM\n");

    return v.it_value.tv_sec * 1024 + ((v.it_value.tv_usec * 1024) / 1e6);
  }
}
