/**                                                                     tab:4
 *  IMPORTANT: READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.  By
 *  downloading, copying, installing or using the software you agree to
 *  this license.  If you do not agree to this license, do not download,
 *  install, copy or use the software.
 *
 *  Copyright (c) 2004-2005 Crossbow Technology, Inc.
 *  Copyright (c) 2002-2003 Intel Corporation.
 *  Copyright (c) 2000-2003 The Regents of the University  of California.    
 *  All rights reserved.
 *
 *  Permission to use, copy, modify, and distribute this software and its
 *  documentation for any purpose, without fee, and without written
 *  agreement is hereby granted, provided that the above copyright
 *  notice, the (updated) modification history and the author appear in
 *  all copies of this source code.
 *
 *  Permission is also granted to distribute this software under the
 *  standard BSD license as contained in the TinyOS distribution.
 *
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 *  ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 *  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 *  PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE INTEL OR ITS
 *  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 *  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 *  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 *  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 *  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 *  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 *  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 *  @author Jason Hill, Philip Levis, Nelson Lee
 *  @author Martin Turon <mturon@xbow.com>
 *
 *  $Id: atmega128hardware.h,v 1.1.2.6 2005-04-18 01:35:58 mturon Exp $
 */

#ifndef _H_atmega128hardware_H
#define _H_atmega128hardware_H

#define _SFR_ASM_COMPAT 1

#include <avr/io.h>
#include <avr/signal.h>
//#include <avr/interrupt.h>
#include <avr/wdt.h>
#include <avr/pgmspace.h>

#define sei()  __asm__ __volatile__ ("sei" ::)
#define cli()  __asm__ __volatile__ ("cli" ::)

#define bzero(x,y)   memset((x), 0, (y))

#ifndef __outw
#define __outw(val, port) outw(port, val);
#endif // __outw

#ifndef __inw
#define __inw(_port) inw(_port)
#endif // __inw

#ifndef __inw_atomic
#define __inw_atomic(__sfrport) ({	\
	uint16_t __t;			\
	bool bStatus;			\
	bStatus = bit_is_set(SREG,7);	\
	cli();				\
	__t = inw(__sfrport);		\
	if (bStatus) sei();		\
	__t;				\
 })
#endif // __inw_atomic

#define TOSH_ASSIGN_PIN(name, port, bit) \
  static inline void TOSH_SET_##name##_PIN() {sbi(PORT##port , bit);} \
  static inline void TOSH_CLR_##name##_PIN() {cbi(PORT##port , bit);} \
  static inline int TOSH_READ_##name##_PIN() \
    { return (inp(PIN##port) & (1 << bit)) != 0; } \
  static inline void TOSH_MAKE_##name##_OUTPUT() {sbi(DDR##port , bit);} \
  static inline void TOSH_MAKE_##name##_INPUT() {cbi(DDR##port , bit);} 

#define TOSH_ASSIGN_OUTPUT_ONLY_PIN(name, port, bit) \
  static inline void TOSH_SET_##name##_PIN() {sbi(PORT##port , bit);} \
  static inline void TOSH_CLR_##name##_PIN() {cbi(PORT##port , bit);} \
  static inline void TOSH_MAKE_##name##_OUTPUT() {;} 

#define TOSH_ALIAS_OUTPUT_ONLY_PIN(alias, connector) \
  static inline void TOSH_SET_##alias##_PIN() {TOSH_SET_##connector##_PIN();} \
  static inline void TOSH_CLR_##alias##_PIN() {TOSH_CLR_##connector##_PIN();} \
  static inline void TOSH_MAKE_##alias##_OUTPUT() {} \

#define TOSH_ALIAS_PIN(alias, connector) \
  static inline void TOSH_SET_##alias##_PIN() {TOSH_SET_##connector##_PIN();} \
  static inline void TOSH_CLR_##alias##_PIN() {TOSH_CLR_##connector##_PIN();} \
  static inline char TOSH_READ_##alias##_PIN() \
    { return TOSH_READ_##connector##_PIN(); } \
  static inline void TOSH_MAKE_##alias##_OUTPUT() \
    { TOSH_MAKE_##connector##_OUTPUT(); } \
  static inline void TOSH_MAKE_##alias##_INPUT() \
    { TOSH_MAKE_##connector##_INPUT(); } 

/** We need slightly different defs than SIGNAL, INTERRUPT */
#define TOSH_SIGNAL(signame) \
  void signame() __attribute__ ((signal, spontaneous, C))

#define TOSH_INTERRUPT(signame) \
  void signame() __attribute__ ((interrupt, spontaneous, C))

/** Macro to create union casting functions. */
#define DEFINE_UNION_CAST(func_name, from_type, to_type) \
  to_type func_name(from_type x) { \
  union {from_type f; to_type t;} c = {f:x}; return c.t; }

/// Bit operators using bit number
#define SET_BIT(port, bit)    (sbi(port, bit))
#define CLR_BIT(port, bit)    (cbi(port, bit))
#define READ_BIT(port, bit)   ((inp(port) & (1 << bit)) != 0)
#define FLIP_BIT(port, bit)   (_MMIO_BYTE(port) ^= (1 << bit))

/// Bit operators using bit flag mask
#define SET_FLAG(port, flag)  ((port) |= (flag))
#define CLR_FLAG(port, flag)  ((port) &= ~(flag))
#define READ_FLAG(port, flag) ((port) & (flag))

void TOSH_wait()
{
    asm volatile("nop");
    asm volatile("nop");
}

void TOSH_sleep()
{
    sbi(MCUCR, SE);
    asm volatile ("sleep");
}

/** Enables interrupts. */
inline void __nesc_enable_interrupt() {
    sei();
}
/** Disables all interrupts. */
inline void __nesc_disable_interrupt() {
    cli();
}

/** Defines data type for storing interrupt mask state during atomic. */
typedef uint8_t __nesc_atomic_t;

/** Saves current interrupt mask state and disables interrupts. */
inline __nesc_atomic_t 
__nesc_atomic_start(void) __attribute__((spontaneous))
{
    __nesc_atomic_t result = inp(SREG);
    __nesc_disable_interrupt();
    return result;
}

/** Restores interrupt mask to original state. */
inline void 
__nesc_atomic_end(__nesc_atomic_t original_SREG) __attribute__((spontaneous))
{
    outp(original_SREG, SREG);
}

inline void
__nesc_atomic_sleep()
{
    //sbi(MCUCR, SE);  power manager will enable/disable sleep
    asm volatile ("sleep");
}

#endif //_H_atmega128hardware_H
