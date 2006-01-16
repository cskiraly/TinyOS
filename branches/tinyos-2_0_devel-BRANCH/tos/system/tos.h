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

/* This macro is used to mark pointers that represent ownership
   transfer in interfaces. See TEP 3 for more discussion. */
#define PASS

struct @atmostonce { };
struct @atleastonce { };
struct @exactlyonce { };

#ifndef TOSSIM
#define dbg(s, ...) 
#define dbgerror(s, ...) 
#define dbg_clear(s, ...) 
#define dbgerror_clear(s, ...) 
#endif
