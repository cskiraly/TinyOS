#if !defined(__CYGWIN__)
#if defined(__MSP430__)
#include <sys/inttypes.h>
#else
#include <inttypes.h>
#endif
#else //cygwin
#include <unistd.h>
#include <stdio.h>
#include <sys/types.h>
#endif

#include <string.h>
#include <stdlib.h>
#include <math.h>
#include <stddef.h>
#include <ctype.h>

typedef uint8_t bool;
enum { FALSE = 0, TRUE = 1 };

typedef int8_t nx_bool __attribute__((nx_base(int8)));
uint16_t TOS_LOCAL_ADDRESS = 1;

typedef uint8_t __nesc_atomic_t;

inline __nesc_atomic_t
__nesc_atomic_start(void) __attribute__((spontaneous))
{
  //__nesc_atomic_t result = SREG;
  //__nesc_disable_interrupt();
  return 0;
}

/** Restores interrupt mask to original state. */
inline void __nesc_atomic_end(__nesc_atomic_t original_SREG) __attribute__((spontaneous))
{
  //SREG = original_SREG;
}

inline void __nesc_enable_interrupt() {
  //sei();
}
/** Disables all interrupts. */
inline void __nesc_disable_interrupt() {
  //cli();
}


#include <sim_event_queue.h>
#include <sim_tossim.h>
#include <sim_mote.h>
#include <stdio.h>

#include <heap.c>
#include <sim_event_queue.c>
#include <sim_tossim.c>
