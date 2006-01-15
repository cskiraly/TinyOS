/// $Id: HplAtm128Timer1P.nc,v 1.1.2.1 2006-01-15 23:44:54 scipio Exp $

/**
 * Copyright (c) 2004-2005 Crossbow Technology, Inc.  All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL CROSSBOW TECHNOLOGY OR ANY OF ITS LICENSORS BE LIABLE TO 
 * ANY PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL 
 * DAMAGES ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN
 * IF CROSSBOW OR ITS LICENSOR HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH 
 * DAMAGE. 
 *
 * CROSSBOW TECHNOLOGY AND ITS LICENSORS SPECIFICALLY DISCLAIM ALL WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY 
 * AND FITNESS FOR A PARTICULAR PURPOSE. THE SOFTWARE PROVIDED HEREUNDER IS 
 * ON AN "AS IS" BASIS, AND NEITHER CROSSBOW NOR ANY LICENSOR HAS ANY 
 * OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR 
 * MODIFICATIONS.
 */

/// @author Martin Turon <mturon@xbow.com>

#include <Atm128Timer.h>

module HplAtm128Timer1P
{
  provides {
    // 16-bit Timers
    interface HplAtm128Timer<uint16_t>   as Timer1;
    interface HplAtm128TimerCtrl16       as Timer1Ctrl;
    interface HplAtm128Capture<uint16_t> as Capture1;
    interface HplAtm128Compare<uint16_t> as Compare1A;
    interface HplAtm128Compare<uint16_t> as Compare1B;
    interface HplAtm128Compare<uint16_t> as Compare1C;
  }
  uses interface HplAtm128TimerCtrl8     as Timer0Ctrl;
}
implementation
{
  //=== Read the current timer value. ===================================
  async command uint16_t Timer1.get() { return TCNT1; }

  //=== Set/clear the current timer value. ==============================
  async command void Timer1.set(uint16_t t) { TCNT1 = t; }

  //=== Read the current timer scale. ===================================
  async command uint8_t Timer1.getScale() { return TCCR1B & 0x7; }

  //=== Turn off the timers. ============================================
  async command void Timer1.off() { call Timer1.setScale(AVR_CLOCK_OFF); }

  //=== Write a new timer scale. ========================================
  async command void Timer1.setScale(uint8_t s)  { 
    Atm128TimerCtrlCapture_t x = call Timer1Ctrl.getCtrlCapture();
    x.bits.cs = s;
    call Timer1Ctrl.setCtrlCapture(x);  
  }

  //=== Read the control registers. =====================================
  async command Atm128TimerCtrlCompare_t Timer1Ctrl.getCtrlCompare() { 
    return *(Atm128TimerCtrlCompare_t*)&TCCR1A; 
  }
  async command Atm128TimerCtrlCapture_t Timer1Ctrl.getCtrlCapture() { 
    return *(Atm128TimerCtrlCapture_t*)&TCCR1B; 
  }
  async command Atm128TimerCtrlClock_t Timer1Ctrl.getCtrlClock() { 
    return *(Atm128TimerCtrlClock_t*)&TCCR1C; 
  }


  //=== Control registers utilities. ==================================
  DEFINE_UNION_CAST(TimerCtrlCompare2int, Atm128TimerCtrlCompare_t, uint16_t);
  DEFINE_UNION_CAST(TimerCtrlCapture2int, Atm128TimerCtrlCapture_t, uint16_t);
  DEFINE_UNION_CAST(TimerCtrlClock2int, Atm128TimerCtrlClock_t, uint16_t);

  //=== Write the control registers. ====================================
  async command void Timer1Ctrl.setCtrlCompare( Atm128_TCCR1A_t x ) { 
    TCCR1A = TimerCtrlCompare2int(x); 
  }
  async command void Timer1Ctrl.setCtrlCapture( Atm128_TCCR1B_t x ) { 
    TCCR1B = TimerCtrlCapture2int(x); 
  }
  async command void Timer1Ctrl.setCtrlClock( Atm128_TCCR1C_t x ) { 
    TCCR1C = TimerCtrlClock2int(x); 
  }

  //=== Read the interrupt mask. =====================================
  async command Atm128_ETIMSK_t Timer1Ctrl.getInterruptMask() { 
    return *(Atm128_ETIMSK_t*)&ETIMSK; 
  }

  //=== Write the interrupt mask. ====================================
  DEFINE_UNION_CAST(TimerMask8_2int, Atm128_TIMSK_t, uint8_t);
  DEFINE_UNION_CAST(TimerMask16_2int, Atm128_ETIMSK_t, uint8_t);

  async command void Timer1Ctrl.setInterruptMask( Atm128_ETIMSK_t x ) { 
    ETIMSK = TimerMask16_2int(x); 
  }

  //=== Read the interrupt flags. =====================================
  async command Atm128_ETIFR_t Timer1Ctrl.getInterruptFlag() { 
    return *(Atm128_ETIFR_t*)&ETIFR; 
  }

  //=== Write the interrupt flags. ====================================
  DEFINE_UNION_CAST(TimerFlags8_2int, Atm128_TIFR_t, uint8_t);
  DEFINE_UNION_CAST(TimerFlags16_2int, Atm128_ETIFR_t, uint8_t);

  async command void Timer1Ctrl.setInterruptFlag( Atm128_ETIFR_t x ) { 
    ETIFR = TimerFlags16_2int(x); 
  }

  //=== Capture 16-bit implementation. ===================================
  async command void Capture1.setEdge(bool up) { WRITE_BIT(TCCR1B,ICES1, up); }

  //=== Timer 16-bit implementation. ===================================
  async command void Timer1.reset()    { TIFR = 1 << TOV1; }
  async command void Capture1.reset()  { TIFR = 1 << ICF1; }
  async command void Compare1A.reset() { TIFR = 1 << OCF1A; }
  async command void Compare1B.reset() { TIFR = 1 << OCF1B; }
  async command void Compare1C.reset() { ETIFR = 1 << OCF1C; }

  async command void Timer1.start()    { SET_BIT(TIMSK,TOIE1); }
  async command void Capture1.start()  { SET_BIT(TIMSK,TICIE1); }
  async command void Compare1A.start() { SET_BIT(TIMSK,OCIE1A); }
  async command void Compare1B.start() { SET_BIT(TIMSK,OCIE1B); }
  async command void Compare1C.start() { SET_BIT(ETIMSK,OCIE1C); }

  async command void Timer1.stop()    { CLR_BIT(ETIMSK,TOIE3); }
  async command void Capture1.stop()  { CLR_BIT(ETIMSK,TICIE1); }
  async command void Compare1A.stop() { CLR_BIT(ETIMSK,OCIE3A); }
  async command void Compare1B.stop() { CLR_BIT(ETIMSK,OCIE3B); }
  async command void Compare1C.stop() { CLR_BIT(ETIMSK,OCIE3C); }

  // Note: Many Timer1 interrupt flags are on Timer0 register
  async command bool Timer1.test() { 
    return (call Timer0Ctrl.getInterruptFlag()).bits.tov1; 
  }
  async command bool Capture1.test()  { 
    return (call Timer0Ctrl.getInterruptFlag()).bits.icf1; 
  }
  async command bool Compare1A.test() { 
    return (call Timer0Ctrl.getInterruptFlag()).bits.ocf1a; 
  }
  async command bool Compare1B.test() { 
    return (call Timer0Ctrl.getInterruptFlag()).bits.ocf1b; 
  }
  async command bool Compare1C.test() { 
    return (call Timer1Ctrl.getInterruptFlag()).bits.ocf1c; 
  }

  // Note: Many Timer1 interrupt mask bits are on Timer0 register
  async command bool Timer1.isOn() {
    return (call Timer0Ctrl.getInterruptMask()).bits.toie1;
  }
  async command bool Capture1.isOn()  {
    return (call Timer0Ctrl.getInterruptMask()).bits.ticie1;
  }
  async command bool Compare1A.isOn() {
    return (call Timer0Ctrl.getInterruptMask()).bits.ocie1a;
  }
  async command bool Compare1B.isOn() {
    return (call Timer0Ctrl.getInterruptMask()).bits.ocie1b;
  }
  async command bool Compare1C.isOn() {
    return (call Timer1Ctrl.getInterruptMask()).bits.ocie1c;
  }

  //=== Read the compare registers. =====================================
  async command uint16_t Compare1A.get() { return OCR1A; }
  async command uint16_t Compare1B.get() { return OCR1B; }
  async command uint16_t Compare1C.get() { return OCR1C; }

  //=== Write the compare registers. ====================================
  async command void Compare1A.set(uint16_t t) { OCR1A = t; }
  async command void Compare1B.set(uint16_t t) { OCR1B = t; }
  async command void Compare1C.set(uint16_t t) { OCR1C = t; }

  //=== Read the capture registers. =====================================
  async command uint16_t Capture1.get() { return ICR1; }

  //=== Write the capture registers. ====================================
  async command void Capture1.set(uint16_t t)  { ICR1 = t; }

  //=== Timer interrupts signals ========================================
  default async event void Compare1A.fired() { }
  AVR_NONATOMIC_HANDLER(SIG_OUTPUT_COMPARE1A) {
    signal Compare1A.fired();
  }
  default async event void Compare1B.fired() { }
  AVR_NONATOMIC_HANDLER(SIG_OUTPUT_COMPARE1B) {
    signal Compare1B.fired();
  }
  default async event void Compare1C.fired() { }
  AVR_NONATOMIC_HANDLER(SIG_OUTPUT_COMPARE1C) {
    signal Compare1C.fired();
  }
  default async event void Capture1.captured(uint16_t time) { }
  AVR_NONATOMIC_HANDLER(SIG_INPUT_CAPTURE1) {
    signal Capture1.captured(call Timer1.get());
  }
  default async event void Timer1.overflow() { }
  AVR_NONATOMIC_HANDLER(SIG_OVERFLOW1) {
    signal Timer1.overflow();
  }
}
