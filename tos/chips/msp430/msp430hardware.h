// $Id: msp430hardware.h,v 1.1.2.6 2005-03-14 03:02:13 jpolastre Exp $

/* "Copyright (c) 2000-2003 The Regents of the University of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement
 * is hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY
 * OF CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 */

// @author Vlado Handziski <handzisk@tkn.tu-berlin.de>
// @author Joe Polastre <polastre@cs.berkeley.edu>
// @author Cory Sharp <cssharp@eecs.berkeley.edu>

#ifndef _H_msp430hardware_h
#define _H_msp430hardware_h

#include <io.h>
#include <signal.h>
#include "msp430regtypes.h"


// CPU memory-mapped register access will cause nesc to issue race condition
// warnings.  Race conditions are a significant conern when accessing CPU
// memory-mapped registers, because they can change even while interrupts
// are disabled.  This means that the standard nesc tools for resolving race
// conditions, atomic statements that disable interrupt handling, do not
// resolve CPU register race conditions.  So, CPU registers access must be
// treated seriously and carefully.

// The macro MSP430REG_NORACE allows individual modules to internally
// redeclare CPU registers as norace, eliminating nesc's race condition
// warnings for their access.  This macro should only be used after the
// specific CPU register use has been verified safe and correct.  Example
// use:
//
//    module MyLowLevelModule
//    {
//      // ...
//    }
//    implementation
//    {
//      MSP430REG_NORACE(TACCTL0);
//      // ...
//    }

#undef norace

#define MSP430REG_NORACE_EXPAND(type,name,addr) \
norace static volatile type name asm(#addr)

#define MSP430REG_NORACE3(type,name,addr) \
MSP430REG_NORACE_EXPAND(type,name,addr)

// MSP430REG_NORACE and MSP430REG_NORACE2 presume naming conventions among
// type, name, and addr, which are defined in the local header
// msp430regtypes.h and mspgcc's header io.h and its children.

#define MSP430REG_NORACE2(rename,name) \
MSP430REG_NORACE3(TYPE_##name,rename,name##_)

#define MSP430REG_NORACE(name) \
MSP430REG_NORACE3(TYPE_##name,name,name##_)

// Avoid the type-punned pointer warnings from gcc 3.3, which are warning about
// creating potentially broken object code.  Union casts are the appropriate work
// around.  Unfortunately, they require a function definiton.
#define DEFINE_UNION_CAST(func_name,to_type,from_type) \
to_type func_name(from_type x) { union {from_type f; to_type t;} c = {f:x}; return c.t; }

// redefine ugly defines from msp-gcc
#ifndef DONT_REDEFINE_SR_FLAGS
#undef C
#undef Z
#undef N
#undef V
#undef GIE
#undef CPUOFF
#undef OSCOFF
#undef SCG0
#undef SCG1
#undef LPM0_bits
#undef LPM1_bits
#undef LPM2_bits
#undef LPM3_bits
#undef LPM4_bits
#define SR_C       0x0001
#define SR_Z       0x0002
#define SR_N       0x0004
#define SR_V       0x0100
#define SR_GIE     0x0008
#define SR_CPUOFF  0x0010
#define SR_OSCOFF  0x0020
#define SR_SCG0    0x0040
#define SR_SCG1    0x0080
#define LPM0_bits           SR_CPUOFF
#define LPM1_bits           SR_SCG0+SR_CPUOFF
#define LPM2_bits           SR_SCG1+SR_CPUOFF
#define LPM3_bits           SR_SCG1+SR_SCG0+SR_CPUOFF
#define LPM4_bits           SR_SCG1+SR_SCG0+SR_OSCOFF+SR_CPUOFF
#endif//DONT_REDEFINE_SR_FLAGS

#ifdef interrupt
#undef interrupt
#endif

#ifdef wakeup
#undef wakeup
#endif

#ifdef signal
#undef signal
#endif

// I2CBusy flag is not defined by current MSP430-GCC
#ifdef __msp430_have_usart0_with_i2c
#define I2CBUSY   (0x01 << 5)
MSP430REG_NORACE2(U0CTLnr,U0CTL);
MSP430REG_NORACE2(I2CTCTLnr,I2CTCTL);
MSP430REG_NORACE2(I2CDCTLnr,I2CDCTL);
#endif

// The signal attribute has opposite meaning in msp430-gcc than in avr-gcc
#define TOSH_SIGNAL(signame) \
void sig_##signame() __attribute__((interrupt (signame), wakeup, C))

// TOSH_INTERRUPT allows nested interrupts
#define TOSH_INTERRUPT(signame) \
void isr_##signame() __attribute__((interrupt (signame), signal, wakeup, C))

inline void TOSH_wait(void)
{
  nop(); nop();
}

#define TOSH_CYCLE_TIME_NS 250

inline void TOSH_wait_250ns(void)
{
  // 4 MHz clock == 1 cycle per 250 ns
  nop();
}

inline void TOSH_uwait(uint16_t u) 
{ 
  uint16_t i;
  if (u < 500)
    for (i=2; i < u; i++) { 
      asm volatile("nop\n\t"
                   "nop\n\t"
                   "nop\n\t"
                   "nop\n\t"
                   ::);
    }
  else
    for (i=0; i < u; i++) { 
      asm volatile("nop\n\t"
                   "nop\n\t"
                   "nop\n\t"
                   "nop\n\t"
                   ::);
    }
  
} 

void __nesc_disable_interrupt()
{
  dint();
  nop();
}

void __nesc_enable_interrupt()
{
  eint();
}

bool are_interrupts_enabled()
{
  return ((READ_SR & SR_GIE) != 0);
}

typedef bool __nesc_atomic_t;

__nesc_atomic_t __nesc_atomic_start(void)
{
  __nesc_atomic_t result = are_interrupts_enabled();
  __nesc_disable_interrupt();
  return result;
}

void __nesc_atomic_end( __nesc_atomic_t reenable_interrupts )
{
  if( reenable_interrupts )
    __nesc_enable_interrupt();
}

//Variable to keep track if Low Power Modes shoud not be used
norace bool LPMode_disabled = FALSE;

void LPMode_enable() {
  LPMode_disabled = FALSE;
}

void LPMode_disable() {
  LPMode_disabled = TRUE;
}

inline void TOSH_sleep() {
  // The LPM we can go down to depends on the clocks used. We never go
  // below LPM3, so ACLK is always enabled, also TimerB clock source
  // is assumed to be ACLK.
  // We check MSP430's TimerA, USART0/1, ADC12 peripheral modules if they
  // use MCLK or SMCLK and switch to the lowest LPM that keeps 
  // the required clock(s) running. 
  //  extern uint8_t TOSH_sched_full;
  //  extern volatile uint8_t TOSH_sched_free;
  __nesc_atomic_t fInterruptFlags;
  uint16_t LPMode_bits = 0;
  
  fInterruptFlags = __nesc_atomic_start(); 
  
  if (LPMode_disabled) { // || (TOSH_sched_full != TOSH_sched_free)) {
    __nesc_atomic_end(fInterruptFlags);
    return;
  } else {
    LPMode_bits = LPM3_bits;
    // TimerA, USART0, USART1 check
    if ( (((TACCTL0 & CCIE) || (TACCTL1 & CCIE) || (TACCTL2 & CCIE))
         && ((TACTL & TASSEL_3) == TASSEL_2))
      || ((ME1 & (UTXE0 | URXE0)) && (U0TCTL & SSEL1))
      || ((ME2 & (UTXE1 | URXE1)) && (U1TCTL & SSEL1)) 
#ifdef __msp430_have_usart0_with_i2c
      // registers end in "nr" to prevent nesC race condition detection
      || ((U0CTLnr & I2CEN) && (I2CTCTLnr & SSEL1) &&
	  (I2CDCTLnr & I2CBUSY) && (U0CTLnr & SYNC) && (U0CTLnr & I2C))
#endif	
      )
      LPMode_bits = LPM1_bits;
    // ADC12 check  
    if (ADC12CTL1 & ADC12BUSY){
      if (!(ADC12CTL0 & MSC) && ((TACTL & TASSEL_3) == TASSEL_2))
         LPMode_bits = LPM1_bits; // TimerA for ADC12 
      else
        switch (ADC12CTL1 & ADC12SSEL_3){
          case ADC12SSEL_2: LPMode_bits = 0; break;
          case ADC12SSEL_3: LPMode_bits = LPM1_bits; break;
        }
    }
    LPMode_bits |= SR_GIE;
    __asm__ __volatile__( "bis  %0, r2" : : "m" ((uint16_t)LPMode_bits) );
  }
}

void __nesc_atomic_sleep()
{
  TOSH_sleep(); // XXX fixme XXX
}

#define SET_FLAG(port, flag) ((port) |= (flag))
#define CLR_FLAG(port, flag) ((port) &= ~(flag))
#define READ_FLAG(port, flag) ((port) & (flag))

// TOSH_ASSIGN_PIN creates functions that are effectively marked as
// "norace".  This means race conditions that result from their use will not
// be detectde by nesc.

#define TOSH_ASSIGN_PIN_HEX(name, port, hex) \
void TOSH_SET_##name##_PIN() { MSP430REG_NORACE2(r,P##port##OUT); r |= hex; } \
void TOSH_CLR_##name##_PIN() { MSP430REG_NORACE2(r,P##port##OUT); r &= ~hex; } \
void TOSH_TOGGLE_##name##_PIN() { MSP430REG_NORACE2(r,P##port##OUT); r ^= hex; } \
uint8_t TOSH_READ_##name##_PIN() { MSP430REG_NORACE2(r,P##port##IN); return (r & hex); } \
void TOSH_MAKE_##name##_OUTPUT() { MSP430REG_NORACE2(r,P##port##DIR); r |= hex; } \
void TOSH_MAKE_##name##_INPUT() { MSP430REG_NORACE2(r,P##port##DIR); r &= ~hex; } \
void TOSH_SEL_##name##_MODFUNC() { MSP430REG_NORACE2(r,P##port##SEL); r |= hex; } \
void TOSH_SEL_##name##_IOFUNC() { MSP430REG_NORACE2(r,P##port##SEL); r &= ~hex; }

#define TOSH_ASSIGN_PIN(name, port, bit) \
TOSH_ASSIGN_PIN_HEX(name,port,(1<<(bit)))

#endif//_H_msp430hardware_h

