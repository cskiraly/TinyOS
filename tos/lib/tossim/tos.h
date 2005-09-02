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

#include <sim_event_queue.h>
#include <sim_tossim.h>
#include <sim_mote.h>
#include <stdio.h>

#include <heap.c>
#include <sim_event_queue.c>
#include <sim_tossim.c>
