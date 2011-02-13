
#ifndef HARDWARE_H
#define HARDWARE_H

#include <signal.h>

static sigset_t old_set;
inline void __nesc_enable_interrupt() { 
  sigprocmask( SIG_SETMASK, &old_set, NULL );
}
inline void __nesc_disable_interrupt() { 
  sigset_t set;
  sigemptyset(&set);
  sigaddset(&set, SIGALRM);
  // sigaddset(&set, SIGIO);
  sigprocmask(SIG_BLOCK, &set, &old_set);
}

typedef uint8_t __nesc_atomic_t;
typedef uint8_t mcu_power_t;

inline __nesc_atomic_t __nesc_atomic_start(void) @spontaneous() {
  __nesc_disable_interrupt();
  return 0;
}

inline void __nesc_atomic_end(__nesc_atomic_t x) @spontaneous() { 
  __nesc_enable_interrupt();
}
inline void __nesc_atomic_sleep() { }

/* Floating-point network-type support */
typedef float nx_float __attribute__((nx_base_be(afloat)));

inline float __nesc_ntoh_afloat(const void *COUNT(sizeof(float)) source) @safe() {
  float f;
  memcpy(&f, source, sizeof(float));
  return f;
}

inline float __nesc_hton_afloat(void *COUNT(sizeof(float)) target, float value) @safe() {
  memcpy(target, &value, sizeof(float));
  return value;
}

// enum so components can override power saving,
// as per TEP 112.
// As this is not a real platform, just set it to 0.
enum {
  TOS_SLEEP_NONE = 0,
};


#endif
