/// $Id: HPLTimerM.nc,v 1.1.2.1 2005-01-20 04:17:32 mturon Exp $

/**
 * Copyright (c) 2004-2005 Crossbow Technology, Inc.  All rights reserved.
 *
 * Permission to use, copy, modify and distribute, this software and 
 * documentation is granted, provided the following conditions are met:
 *   1. The above copyright notice and these conditions, along with the 
 *      following disclaimers, appear in all copies of the software.
 *   2. When the use, copying, modification or distribution is for COMMERCIAL 
 *      purposes (i.e., any use other than academic research), then the 
 *      software (including all modifications of the software) may be used 
 *      ONLY with hardware manufactured by and purchased from Crossbow 
 *      Technology, unless you obtain separate written permission from, 
 *      and pay appropriate fees to, Crossbow. For example, no right to copy 
 *      and use the software on non-Crossbow hardware, if the use is 
 *      commercial in nature, is permitted under this license. 
 *   3. When the use, copying, modification or distribution is for 
 *      NON-COMMERCIAL PURPOSES (i.e., academic research use only), the 
 *      software may be used, whether or not with Crossbow hardware, without 
 *      any fee to Crossbow. 
 * 
 * IN NO EVENT SHALL CROSSBOW TECHNOLOGY OR ANY OF ITS LICENSORS BE LIABLE TO 
 * ANY PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL 
 * DAMAGES ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN
 * IF CROSSBOW OR ITS LICENSOR HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH 
 * DAMAGE. CROSSBOW TECHNOLOGY AND ITS LICENSORS SPECIFICALLY DISCLAIM ALL 
 * WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF 
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE SOFTWARE PROVIDED
 * HEREUNDER IS ON AN "AS IS" BASIS, AND NEITHER CROSSBOW NOR ANY LICENSOR HAS
 * ANY OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR 
 * MODIFICATIONS.
 */

/// @author Martin Turon <mturon@xbow.com>

includes ATm128Timer;

module HPLTimerM
{
  // 8-bit Timers
  provides interface ATm128Timer8 as Timer0;
  provides interface ATm128Timer8 as Timer2;

  // 16-bit Timers
  provides interface ATm128Timer16 as Timer1;
  provides interface ATm128Timer16 as Timer3;
}
implementation
{
  //=== Read the current timer value. ===================================
  async command uint8_t Timer0.get() { return __inb_atomic(TCNT0); }
  async command uint8_t Timer2.get() { return __inb_atomic(TCNT2); }
  async command uint16_t Timer1.get() { return __inw_atomic(TCNT1L); }
  async command uint16_t Timer3.get() { return __inw_atomic(TCNT3L); }

  //=== Set/clear the current timer value. ==============================
  async command void Timer0.set(uint8_t t) { atomic TCNT0 = t; }
  async command void Timer2.set(uint8_t t) { atomic TCNT2 = t; }
  async command void Timer1.set(uint16_t t) { atomic TCNT1L = t; }
  async command void Timer3.set(uint16_t t) { atomic TCNT3L = t; }

  //=== Read the control registers. =====================================
  async command ATm128TimerControl_t Timer0.getControl() { 
      return *(ATm128TimerControl_t*)&__inb_atomic(TCCR0); 
  }
  async command ATm128TimerControl_t Timer2.getControl() { 
      return *(ATm128TimerControl_t*)&__inb_atomic(TCCR2); 
  }
  async command ATm128_TCCR1A_t Timer1.getCtrlCompare() { 
      return *(ATm128_TCCR1A_t*)&__inb_atomic(TCCR1A); 
  }
  async command ATm128_TCCR3A_t Timer3.getCtrlCompare() { 
      return *(ATm128_TCCR3A_t*)&__inb_atomic(TCCR3A); 
  }
  async command ATm128_TCCR1B_t Timer1.getCtrlCapture() { 
      return *(ATm128_TCCR1B_t*)&__inb_atomic(TCCR1B); 
  }
  async command ATm128_TCCR3B_t Timer3.getCtrlCapture() { 
      return *(ATm128_TCCR3B_t*)&__inb_atomic(TCCR3B); 
  }
  async command ATm128_TCCR1C_t Timer1.getCtrlClock() { 
      return *(ATm128_TCCR1C_t*)&__inb_atomic(TCCR1C); 
  }
  async command ATm128_TCCR3C_t Timer3.getCtrlClock() { 
      return *(ATm128_TCCR3C_t*)&__inb_atomic(TCCR3C); 
  }


  //=== Control registers utilities. ==================================
  uint8_t TimerControl2int( ATm128TimerControl_t tc )
  {
    typedef union { ATm128TimerControl_t x; uint8_t i; } convert_t;
    convert_t a = { x:cc };
    return a.i;
  }

  uint16_t TimerCtrlCompare2int( ATm128TimerCtrlCompare_t tc )
  {
    typedef union { ATm128TimerCtrlCompare_t x; uint16_t i; } convert_t;
    convert_t a = { x:cc };
    return a.i;
  }

  uint16_t TimerCtrlCapture2int ATm128TimerCtrlCapture_t tc )
  {
    typedef union { ATm128TimerCtrlCapture_t x; uint16_t i; } convert_t;
    convert_t a = { x:cc };
    return a.i;
  }

  uint16_t TimerCtrlClock2int( ATm128TimerCtrlClock_t tc )
  {
    typedef union { ATm128TimerCtrlClock_t x; uint16_t i; } convert_t;
    convert_t a = { x:cc };
    return a.i;
  }

  //=== Write the control registers. ====================================
  async command void Timer0.setControl( ATm128TimerControl_t x ) { 
      TCCR0 = TimerControl2int(x); 
  }
  async command void Timer2.setControl( ATm128TimerControl_t x ) { 
      TCCR2 = TimerControl2int(x); 
  }
  async command void Timer1.setCtrlCompare( ATm128_TCCR1A_t x ) { 
      TCCR1A = TimerCtrlCompare2int(x); 
  }
  async command void Timer1.setCtrlCapture( ATm128_TCCR1B_t x ) { 
      TCCR1B = TimerCtrlCapture2int(x); 
  }
  async command void Timer1.setCtrlClock( ATm128_TCCR1C_t x ) { 
      TCCR1C = TimerCtrlClock2int(x); 
  }
  async command void Timer3.setCtrlCompare( ATm128_TCCR3A_t x ) { 
      TCCR3A = TimerCtrlCompare2int(x); 
  }
  async command void Timer3.setCtrlCapture( ATm128_TCCR3B_t x ) { 
      TCCR3B = TimerCtrlCapture2int(x); 
  }
  async command void Timer3.setCtrlClock( ATm128_TCCR3C_t x ) { 
      TCCR3C = TimerCtrlClock2int(x); 
  }

  //=== Read the interrupt mask. =====================================
  async command ATm128_TIMSK_t Timer0.getInerruptMask() { 
      return *(ATm128_TIMSK_t*)&__inb_atomic(TIMSK); 
  }
  async command ATm128_TIMSK_t Timer2.getInerruptMask() { 
      return *(ATm128_TIMSK_t*)&__inb_atomic(TIMSK); 
  }
  async command ATm128_ETIMSK_t Timer1.getInerruptMask() { 
      return *(ATm128_ETIMSK_t*)&__inb_atomic(ETIMSK); 
  }
  async command ATm128_ETIMSK_t Timer3.getInerruptMask() { 
      return *(ATm128_ETIMSK_t*)&__inb_atomic(ETIMSK); 
  }

  //=== Write the interrupt mask. ====================================
  uint8_t TimerMask8_2int( ATm128_TIMSK_t tc )
  {
    typedef union { ATm128_TIMSK_t x; uint8_t i; } convert_t;
    convert_t a = { x:cc };
    return a.i;
  }
  uint8_t TimerMask16_2int( ATm128_ETIMSK_t tc )
  {
    typedef union { ATm128_ETIMSK_t x; uint8_t i; } convert_t;
    convert_t a = { x:cc };
    return a.i;
  }

  async command void Timer0.setInterruptMask( ATm128_TIMSK_t x ) { 
      TIMSK = TimerMask8_2int(x); 
  }
  async command void Timer2.setInterruptMask( ATm128_TIMSK_t x ) { 
      TIMSK = TimerMask8_2int(x); 
  }
  async command void Timer1.setInterruptMask( ATm128_ETIMSK_t x ) { 
      ETIMSK = TimerMask16_2int(x); 
  }
  async command void Timer3.setInterruptMask( ATm128_ETIMSK_t x ) { 
      ETIMSK = TimerMask16_2int(x); 
  }

  //=== Read the interrupt flags. =====================================
  async command ATm128_TIFR_t Timer0.getInerruptFlags() { 
      return *(ATm128_TIFR_t*)&__inb_atomic(TIFR); 
  }
  async command ATm128_TIFR_t Timer2.getInerruptFlags() { 
      return *(ATm128_TIFR_t*)&__inb_atomic(TIFR); 
  }
  async command ATm128_ETIFR_t Timer1.getInerruptFlags() { 
      return *(ATm128_ETIFR_t*)&__inb_atomic(ETIFR); 
  }
  async command ATm128_ETIFR_t Timer3.getInerruptFlags() { 
      return *(ATm128_ETIFR_t*)&__inb_atomic(ETIFR); 
  }

  //=== Write the interrupt flags. ====================================
  uint8_t TimerFlags8_2int( ATm128_TIFR_t tc )
  {
    typedef union { ATm128_TIFR_t x; uint8_t i; } convert_t;
    convert_t a = { x:cc };
    return a.i;
  }
  uint8_t TimerFlags16_2int( ATm128_ETIFR_t tc )
  {
    typedef union { ATm128_ETIFR_t x; uint8_t i; } convert_t;
    convert_t a = { x:cc };
    return a.i;
  }

  async command void Timer0.setInterruptFlags( ATm128_TIFR_t x ) { 
      TIFR = TimerFlags8_2int(x); 
  }
  async command void Timer2.setInterruptMask( ATm128_TIFR_t x ) { 
      TIFR = TimerFlags8_2int(x); 
  }
  async command void Timer1.setInterruptMask( ATm128_ETIFR_t x ) { 
      ETIFR = TimerFlags16_2int(x); 
  }
  async command void Timer3.setInterruptMask( ATm128_ETIFR_t x ) { 
      ETIFR = TimerFlags16_2int(x); 
  }

  //=== Read the compare registers. =====================================
  async command uint8_t Timer0.getCompare() { return __inb_atomic(OCR0); }
  async command uint8_t Timer2.getCompare() { return __inb_atomic(OCR2); }
  async command uint16_t Timer1.getCompareA() { return __inw_atomic(OCR1AL); }
  async command uint16_t Timer1.getCompareB() { return __inw_atomic(OCR1BL); }
  async command uint16_t Timer1.getCompareC() { return __inw_atomic(OCR1CL); }
  async command uint16_t Timer3.getCompareA() { return __inw_atomic(OCR3AL); }
  async command uint16_t Timer3.getCompareB() { return __inw_atomic(OCR3BL); }
  async command uint16_t Timer3.getCompareC() { return __inw_atomic(OCR3CL); }

  //=== Write the compare registers. ====================================
  async command void Timer0.setCompare(uint8_t t)  { atomic OCR0 = t; }
  async command void Timer2.setCompare(uint8_t t)  { atomic OCR2 = t; }
  async command void Timer1.setCompareA(uint16_t t) { atomic OCR1AL = t; }
  async command void Timer1.setCompareB(uint16_t t) { atomic OCR1BL = t; }
  async command void Timer1.setCompareC(uint16_t t) { atomic OCR1CL = t; }
  async command void Timer3.setCompareA(uint16_t t) { atomic OCR3AL = t; }
  async command void Timer3.setCompareB(uint16_t t) { atomic OCR3BL = t; }
  async command void Timer3.setCompareC(uint16_t t) { atomic OCR3CL = t; }

  //=== Read the capture registers. =====================================
  async command uint8_t Timer1.getCapture() { return __inw_atomic(ICR1L); }
  async command uint8_t Timer3.getCapture() { return __inw_atomic(ICR3L); }

  //=== Write the capture registers. ====================================
  async command void Timer1.setCompare(uint16_t t)  { atomic ICR1L = t; }
  async command void Timer3.setCompare(uint16_t t)  { atomic ICR3L = t; }

  //=== Timer interrupts signals ========================================
  default async event void Timer0.fired() { }
  default async event void Timer0.overflow() { }

  default async event void Timer2.fired() { }
  default async event void Timer2.overflow() { }

  default async event void Timer1.firedA() { }
  default async event void Timer1.firedB() { }
  default async event void Timer1.firedC() { }
  default async event void Timer1.captured(uint16_t time) { }
  default async event void Timer1.overflow() { }

  default async event void Timer3.firedA() { }
  default async event void Timer3.firedB() { }
  default async event void Timer3.firedC() { }
  default async event void Timer3.captured(uint16_t time) { }
  default async event void Timer3.overflow() { }
}

