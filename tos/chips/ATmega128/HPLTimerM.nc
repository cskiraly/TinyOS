/// $Id: HPLTimerM.nc,v 1.1.2.3 2005-01-26 22:31:58 mturon Exp $

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
  provides interface ATm128Timer16Compare as Compare1A;
  provides interface ATm128Timer16Compare as Compare1B;
  provides interface ATm128Timer16Compare as Compare1C;

  provides interface ATm128Timer16 as Timer3;
  provides interface ATm128Timer16Compare as Compare3A;
  provides interface ATm128Timer16Compare as Compare3B;
  provides interface ATm128Timer16Compare as Compare3C;
}
implementation
{
  //=== Read the current timer value. ===================================
  async command uint8_t Timer0.get() { return __inb_atomic(TCNT0); }
  async command uint8_t Timer2.get() { return __inb_atomic(TCNT2); }
  async command uint16_t Timer1.get() { return __inw_atomic(TCNT1); }
  async command uint16_t Timer3.get() { return __inw_atomic(TCNT3); }

  //=== Set/clear the current timer value. ==============================
  async command void Timer0.set(uint8_t t) { atomic outb(TCNT0,t); }
  async command void Timer2.set(uint8_t t) { atomic outb(TCNT2,t); }
  async command void Timer1.set(uint16_t t) { atomic outw(TCNT1,t); }
  async command void Timer3.set(uint16_t t) { atomic outw(TCNT3,t); }

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
  DEFINE_UNION_CAST(TimerControl2int, ATm128TimerControl_t, uint8_t);
  DEFINE_UNION_CAST(TimerCtrlCompare2int, ATm128TimerCtrlCompare_t, uint16_t);
  DEFINE_UNION_CAST(TimerCtrlCapture2int, ATm128TimerCtrlCapture_t, uint16_t);
  DEFINE_UNION_CAST(TimerCtrlClock2int, ATm128TimerCtrlClock_t, uint16_t);

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
  DEFINE_UNION_CAST(TimerMask8_2int, ATm128_TIMSK_t, uint8_t);
  DEFINE_UNION_CAST(TimerMask16_2int, ATm128_ETIMSK_t, uint8_t);

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
  async command ATm128_TIFR_t Timer0.getInerruptFlag() { 
      return *(ATm128_TIFR_t*)&__inb_atomic(TIFR); 
  }
  async command ATm128_TIFR_t Timer2.getInerruptFlag() { 
      return *(ATm128_TIFR_t*)&__inb_atomic(TIFR); 
  }
  async command ATm128_ETIFR_t Timer1.getInerruptFlag() { 
      return *(ATm128_ETIFR_t*)&__inb_atomic(ETIFR); 
  }
  async command ATm128_ETIFR_t Timer3.getInerruptFlag() { 
      return *(ATm128_ETIFR_t*)&__inb_atomic(ETIFR); 
  }

  //=== Write the interrupt flags. ====================================
  DEFINE_UNION_CAST(TimerFlags8_2int, ATm128_TIFR_t, uint8_t);
  DEFINE_UNION_CAST(TimerFlags16_2int, ATm128_ETIFR_t, uint8_t);

  async command void Timer0.setInterruptFlag( ATm128_TIFR_t x ) { 
      TIFR = TimerFlags8_2int(x); 
  }
  async command void Timer2.setInterruptFlag( ATm128_TIFR_t x ) { 
      TIFR = TimerFlags8_2int(x); 
  }
  async command void Timer1.setInterruptFlag( ATm128_ETIFR_t x ) { 
      ETIFR = TimerFlags16_2int(x); 
  }
  async command void Timer3.setInterruptFlag( ATm128_ETIFR_t x ) { 
      ETIFR = TimerFlags16_2int(x); 
  }

  //=== Interrupt bit utilities. ======================================
  async command void Timer0.resetCompare()  { sbi(TIFR,OCF0); }
  async command void Timer0.startCompare()  { sbi(TIMSK,OCIE0); }
  async command void Timer0.stopCompare()   { cbi(TIMSK,OCIE0); }
  async command void Timer0.resetOverflow() { sbi(TIFR,TOV0); }
  async command void Timer0.startOverflow() { sbi(TIMSK,TOIE0); }
  async command void Timer0.stopOverflow()  { cbi(TIMSK,TOIE0); }
  async command bool Timer0.testOverflow() { 
      return Timer0.getInterruptFlag().tov0; 
  }
  async command bool Timer0.testCompare()  { 
      return Timer0.getInterruptFlag().ocf0; 
  }

  async command void Timer2.resetCompare()  { sbi(TIFR,OCF2); }
  async command void Timer2.startCompare()  { sbi(TIMSK,OCIE0); }
  async command void Timer2.stopCompare()   { cbi(TIMSK,OCIE0); }
  async command void Timer2.resetOverflow() { sbi(TIFR,TOV2); }
  async command void Timer2.startOverflow() { sbi(TIMSK,TOIE0); }
  async command void Timer2.stopOverflow()  { cbi(TIMSK,TOIE0); }
  async command bool Timer2.testOverflow() { 
      return Timer2.getInterruptFlag().tov2; 
  }
  async command bool Timer2.testCompare()  { 
      return Timer2.getInterruptFlag().ocf2; 
  }

  async command void Timer1.resetOverflow() { sbi(TIFR,TOV1); }
  async command void Timer1.resetCapture()  { sbi(TIFR,ICF1); }
  async command void Compare1A.reset() { sbi(TIFR,OCF1A); }
  async command void Compare1B.reset() { sbi(TIFR,OCF1B); }
  async command void Compare1C.reset() { sbi(ETIFR,OCF1C); }

  async command void Timer1.startOverflow() { sbi(TIMSK,TOIE1); }
  async command void Timer1.startCapture()  { sbi(TIMSK,TICIE1); }
  async command void Compare1A.start() { sbi(TIMSK,OCIE1A); }
  async command void Compare1B.start() { sbi(TIMSK,OCIE1B); }
  async command void Compare1C.start() { sbi(ETIMSK,OCIE1C); }

  async command void Timer1.stopOverflow() { cbi(ETIMSK,TOIE3); }
  async command void Timer1.stopCapture()  { cbi(ETIMSK,TICIE1); }
  async command void Compare1A.stop() { cbi(ETIMSK,OCIE3A); }
  async command void Compare1B.stop() { cbi(ETIMSK,OCIE3B); }
  async command void Compare1C.stop() { cbi(ETIMSK,OCIE3C); }

  // Note: Many Timer1 interrupt flags are on Timer0 register
  async command bool Timer1.testOverflow() { 
      return Timer0.getInterruptFlag().tov1; 
  }
  async command bool Timer1.testCapture()  { 
      return Timer0.getInterruptFlag().icf1; 
  }
  async command bool Compare1A.test() { 
      return Timer0.getInterruptFlag().ocf1a; 
  }
  async command bool Compare1B.test() { 
      return Timer0.getInterruptFlag().ocf1b; 
  }
  async command bool Compare1C.test() { 
      return Timer1.getInterruptFlag().ocf1c; 
  }

  // Note: Many Timer1 interrupt mask bits are on Timer0 register
  async command bool Timer1.checkOverflow() {
      return Timer0.getInterruptMask().toie1;
  }
  async command bool Timer1.checkCapture()  {
      return Timer0.getInterruptMask().ticie1;
  }
  async command bool Compare1A.check() {
      return Timer0.getInterruptMask().ocie1a;
  }
  async command bool Compare1B.check() {
      return Timer0.getInterruptMask().ocie1b;
  }
  async command bool Compare1C.check() {
      return Timer1.getInterruptMask().ocie1c;
  }

  async command void Timer3.resetOverflow() { sbi(ETIFR,TOV3); }
  async command void Timer3.resetCapture()  { sbi(ETIFR,ICF3); }
  async command void Compare3A.reset() { sbi(ETIFR,OCF3A); }
  async command void Compare3B.reset() { sbi(ETIFR,OCF3B); }
  async command void Compare3A.reset() { sbi(ETIFR,OCF3C); }

  async command void Timer3.startOverflow() { sbi(ETIMSK,TOIE3); }
  async command void Timer3.startCapture()  { sbi(ETIMSK,TICIE3); }
  async command void Compare3A.start() { sbi(ETIMSK,OCIE3A); }
  async command void Compare3B.start() { sbi(ETIMSK,OCIE3B); }
  async command void Compare3C.start() { sbi(ETIMSK,OCIE3C); }

  async command void Timer3.stopOverflow() { cbi(ETIMSK,TOIE3); }
  async command void Timer3.stopCapture()  { cbi(ETIMSK,TICIE3); }
  async command void Compare3A.stop() { cbi(ETIMSK,OCIE3A); }
  async command void Compare3B.stop() { cbi(ETIMSK,OCIE3B); }
  async command void Compare3C.stop() { cbi(ETIMSK,OCIE3C); }

  async command bool Timer3.testOverflow() { 
      return Timer3.getInterruptFlag().tov3; 
  }
  async command bool Timer3.testCapture()  { 
      return Timer3.getInterruptFlag().icf3; 
  }
  async command bool Compare3A.test() { 
      return Timer3.getInterruptFlag().ocf3a; 
  }
  async command bool Compare3B.test() { 
      return Timer3.getInterruptFlag().ocf3b; 
  }
  async command bool Compare3C.test() { 
      return Timer3.getInterruptFlag().ocf3c; 
  }

  async command bool Timer3.checkOverflow() {
      return Timer3.getInterruptMask().toie3;
  }
  async command bool Timer3.checkCapture()  {
      return Timer3.getInterruptMask().ticie3;
  }
  async command bool Compare3A.check() {
      return Timer3.getInterruptMask().ocie3a;
  }
  async command bool Compare3B.check() {
      return Timer3.getInterruptMask().ocie3b;
  }
  async command bool Compare3C.check() {
      return Timer3.getInterruptMask().ocie3c;
  }

  //=== Read the compare registers. =====================================
  async command uint8_t Timer0.getCompare() { return __inb_atomic(OCR0); }
  async command uint8_t Timer2.getCompare() { return __inb_atomic(OCR2); }
  async command uint16_t Compare1A.get() { return __inw_atomic(OCR1A); }
  async command uint16_t Compare1B.get() { return __inw_atomic(OCR1B); }
  async command uint16_t Compare1C.get() { return __inw_atomic(OCR1C); }
  async command uint16_t Compare3A.get() { return __inw_atomic(OCR3A); }
  async command uint16_t Compare3B.get() { return __inw_atomic(OCR3B); }
  async command uint16_t Compare3C.get() { return __inw_atomic(OCR3C); }

  //=== Write the compare registers. ====================================
  async command void Timer0.setCompare(uint8_t t)  { atomic outb(OCR0,t); }
  async command void Timer2.setCompare(uint8_t t)  { atomic outb(OCR2,t); }
  async command void Compare1A.set(uint16_t t) { atomic outw(OCR1A,t); }
  async command void Compare1B.set(uint16_t t) { atomic outw(OCR1B,t); }
  async command void Compare1C.set(uint16_t t) { atomic outw(OCR1C,t); }
  async command void Compare3A.set(uint16_t t) { atomic outw(OCR3A,t); }
  async command void Compare3B.set(uint16_t t) { atomic outw(OCR3B,t); }
  async command void Compare3C.set(uint16_t t) { atomic outw(OCR3C,t); }

  //=== Read the capture registers. =====================================
  async command uint8_t Timer1.getCapture() { return __inw_atomic(ICR1); }
  async command uint8_t Timer3.getCapture() { return __inw_atomic(ICR3); }

  //=== Write the capture registers. ====================================
  async command void Timer1.setCapture(uint16_t t)  { atomic outw(ICR1,t); }
  async command void Timer3.setCapture(uint16_t t)  { atomic outw(ICR3,t); }

  //=== Timer interrupts signals ========================================
  default async event void Timer0.fired() { }
  TOSH_INTERRUPT(SIG_OUTPUT_COMPARE0) {
    signal Timer0.fired();
  }
  default async event void Timer0.overflow() { }
  TOSH_INTERRUPT(SIG_OUTPUT_OVERFLOW0) {
    signal Timer0.overflow();
  }


  default async event void Timer2.fired() { }
  TOSH_INTERRUPT(SIG_OUTPUT_COMPARE2) {
    signal Timer2.fired();
  }
  default async event void Timer2.overflow() { }
  TOSH_INTERRUPT(SIG_OUTPUT_OVERFLOW2) {
    signal Timer2.overflow();
  }


  default async event void Compare1A.fired() { }
  TOSH_INTERRUPT(SIG_OUTPUT_COMPARE1A) {
    signal Compare1A.fired();
  }
  default async event void Compare1B.fired() { }
  TOSH_INTERRUPT(SIG_OUTPUT_COMPARE1B) {
    signal Compare1B.fired();
  }
  default async event void Compare1C.fired() { }
  TOSH_INTERRUPT(SIG_OUTPUT_COMPARE1C) {
    signal Compare1C.fired();
  }
  default async event void Timer1.captured(uint16_t time) { }
  TOSH_INTERRUPT(SIG_INPUT_CAPTURE1) {
    signal Timer1.captured(Timer1.get());
  }
  default async event void Timer1.overflow() { }
  TOSH_INTERRUPT(SIG_OUTPUT_OVERFLOW1) {
    signal Timer1.overflow();
  }


  default async event void Compare3A.fired() { }
  TOSH_INTERRUPT(SIG_OUTPUT_COMPARE3A) {
    signal Timer3.fired();
  }
  default async event void Compare3A.fired() { }
  TOSH_INTERRUPT(SIG_OUTPUT_COMPARE3B) {
    signal Timer3.fired();
  }
  default async event void Compare3C.fired() { }
  TOSH_INTERRUPT(SIG_OUTPUT_COMPARE3C) {
    signal Timer3.fired();
  }
  default async event void Timer3.captured(uint16_t time) { }
  TOSH_INTERRUPT(SIG_INPUT_CAPTURE3) {
    signal Timer3.captured(Timer3.get());
  }
  default async event void Timer3.overflow() { }
  TOSH_INTERRUPT(SIG_OUTPUT_OVERFLOW3) {
    signal Timer3.overflow();
  }
}

