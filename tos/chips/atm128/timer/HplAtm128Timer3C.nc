/// $Id: HplAtm128Timer3C.nc,v 1.1.2.1 2006-01-15 23:44:54 scipio Exp $

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

module HplAtm128Timer3C
{
  provides {
    interface HplAtm128Timer<uint16_t>   as Timer3;
    interface HplAtm128TimerCtrl16       as Timer3Ctrl;
    interface HplAtm128Capture<uint16_t> as Capture3;
    interface HplAtm128Compare<uint16_t> as Compare3A;
    interface HplAtm128Compare<uint16_t> as Compare3B;
    interface HplAtm128Compare<uint16_t> as Compare3C;
  }
}
implementation
{
  //=== Read the current timer value. ===================================
  async command uint16_t Timer3.get() { return TCNT3; }

  //=== Set/clear the current timer value. ==============================
  async command void Timer3.set(uint16_t t) { TCNT3 = t; }

  //=== Read the current timer scale. ===================================
  async command uint8_t Timer3.getScale() { return TCCR3B & 0x7; }

  //=== Turn off the timers. ============================================
  async command void Timer3.off() { call Timer3.setScale(AVR_CLOCK_OFF); }

  //=== Write a new timer scale. ========================================
  async command void Timer3.setScale(uint8_t s)  { 
    Atm128TimerCtrlCapture_t x = call Timer3Ctrl.getCtrlCapture();
    x.bits.cs = s;
    call Timer3Ctrl.setCtrlCapture(x);  
  }

  //=== Read the control registers. =====================================
  async command Atm128TimerCtrlCompare_t Timer3Ctrl.getCtrlCompare() { 
    return *(Atm128TimerCtrlCompare_t*)&TCCR3A; 
  }
  async command Atm128TimerCtrlCapture_t Timer3Ctrl.getCtrlCapture() { 
    return *(Atm128TimerCtrlCapture_t*)&TCCR3B; 
  }
  async command Atm128TimerCtrlClock_t Timer3Ctrl.getCtrlClock() { 
    return *(Atm128TimerCtrlClock_t*)&TCCR3C; 
  }


  //=== Control registers utilities. ==================================
  DEFINE_UNION_CAST(TimerCtrlCompare2int, Atm128TimerCtrlCompare_t, uint16_t);
  DEFINE_UNION_CAST(TimerCtrlCapture2int, Atm128TimerCtrlCapture_t, uint16_t);
  DEFINE_UNION_CAST(TimerCtrlClock2int, Atm128TimerCtrlClock_t, uint16_t);

  //=== Write the control registers. ====================================
  async command void Timer3Ctrl.setCtrlCompare( Atm128_TCCR3A_t x ) { 
    TCCR3A = TimerCtrlCompare2int(x); 
  }
  async command void Timer3Ctrl.setCtrlCapture( Atm128_TCCR3B_t x ) { 
    TCCR3B = TimerCtrlCapture2int(x); 
  }
  async command void Timer3Ctrl.setCtrlClock( Atm128_TCCR3C_t x ) { 
    TCCR3C = TimerCtrlClock2int(x); 
  }

  //=== Read the interrupt mask. =====================================
  async command Atm128_ETIMSK_t Timer3Ctrl.getInterruptMask() { 
    return *(Atm128_ETIMSK_t*)&ETIMSK; 
  }

  //=== Write the interrupt mask. ====================================
  DEFINE_UNION_CAST(TimerMask16_2int, Atm128_ETIMSK_t, uint8_t);

  async command void Timer3Ctrl.setInterruptMask( Atm128_ETIMSK_t x ) { 
    ETIMSK = TimerMask16_2int(x); 
  }

  //=== Read the interrupt flags. =====================================
  async command Atm128_ETIFR_t Timer3Ctrl.getInterruptFlag() { 
    return *(Atm128_ETIFR_t*)&ETIFR; 
  }

  //=== Write the interrupt flags. ====================================
  DEFINE_UNION_CAST(TimerFlags16_2int, Atm128_ETIFR_t, uint8_t);

  async command void Timer3Ctrl.setInterruptFlag( Atm128_ETIFR_t x ) { 
    ETIFR = TimerFlags16_2int(x); 
  }

  //=== Capture 16-bit implementation. ===================================
  async command void Capture3.setEdge(bool up) { WRITE_BIT(TCCR3B,ICES3, up); }

  //=== Timer 16-bit implementation. ===================================
  async command void Timer3.reset()    { ETIFR = 1 << TOV3; }
  async command void Capture3.reset()  { ETIFR = 1 << ICF3; }
  async command void Compare3A.reset() { ETIFR = 1 << OCF3A; }
  async command void Compare3B.reset() { ETIFR = 1 << OCF3B; }
  async command void Compare3C.reset() { ETIFR = 1 << OCF3C; }

  async command void Timer3.start()    { SET_BIT(ETIMSK,TOIE3); }
  async command void Capture3.start()  { SET_BIT(ETIMSK,TICIE3); }
  async command void Compare3A.start() { SET_BIT(ETIMSK,OCIE3A); }
  async command void Compare3B.start() { SET_BIT(ETIMSK,OCIE3B); }
  async command void Compare3C.start() { SET_BIT(ETIMSK,OCIE3C); }

  async command void Timer3.stop()    { CLR_BIT(ETIMSK,TOIE3); }
  async command void Capture3.stop()  { CLR_BIT(ETIMSK,TICIE3); }
  async command void Compare3A.stop() { CLR_BIT(ETIMSK,OCIE3A); }
  async command void Compare3B.stop() { CLR_BIT(ETIMSK,OCIE3B); }
  async command void Compare3C.stop() { CLR_BIT(ETIMSK,OCIE3C); }

  async command bool Timer3.test() { 
    return (call Timer3Ctrl.getInterruptFlag()).bits.tov3; 
  }
  async command bool Capture3.test()  { 
    return (call Timer3Ctrl.getInterruptFlag()).bits.icf3; 
  }
  async command bool Compare3A.test() { 
    return (call Timer3Ctrl.getInterruptFlag()).bits.ocf3a; 
  }
  async command bool Compare3B.test() { 
    return (call Timer3Ctrl.getInterruptFlag()).bits.ocf3b; 
  }
  async command bool Compare3C.test() { 
    return (call Timer3Ctrl.getInterruptFlag()).bits.ocf3c; 
  }

  async command bool Timer3.isOn() {
    return (call Timer3Ctrl.getInterruptMask()).bits.toie3;
  }
  async command bool Capture3.isOn()  {
    return (call Timer3Ctrl.getInterruptMask()).bits.ticie3;
  }
  async command bool Compare3A.isOn() {
    return (call Timer3Ctrl.getInterruptMask()).bits.ocie3a;
  }
  async command bool Compare3B.isOn() {
    return (call Timer3Ctrl.getInterruptMask()).bits.ocie3b;
  }
  async command bool Compare3C.isOn() {
    return (call Timer3Ctrl.getInterruptMask()).bits.ocie3c;
  }

  //=== Read the compare registers. =====================================
  async command uint16_t Compare3A.get() { return OCR3A; }
  async command uint16_t Compare3B.get() { return OCR3B; }
  async command uint16_t Compare3C.get() { return OCR3C; }

  //=== Write the compare registers. ====================================
  async command void Compare3A.set(uint16_t t) { OCR3A = t; }
  async command void Compare3B.set(uint16_t t) { OCR3B = t; }
  async command void Compare3C.set(uint16_t t) { OCR3C = t; }

  //=== Read the capture registers. =====================================
  async command uint16_t Capture3.get() { return ICR3; }

  //=== Write the capture registers. ====================================
  async command void Capture3.set(uint16_t t)  { ICR3 = t; }

  //=== Timer interrupts signals ========================================
  default async event void Compare3A.fired() { }
  AVR_NONATOMIC_HANDLER(SIG_OUTPUT_COMPARE3A) {
    signal Compare3A.fired();
  }
  default async event void Compare3B.fired() { }
  AVR_NONATOMIC_HANDLER(SIG_OUTPUT_COMPARE3B) {
    signal Compare3B.fired();
  }
  default async event void Compare3C.fired() { }
  AVR_NONATOMIC_HANDLER(SIG_OUTPUT_COMPARE3C) {
    signal Compare3C.fired();
  }
  default async event void Capture3.captured(uint16_t time) { }
  AVR_NONATOMIC_HANDLER(SIG_INPUT_CAPTURE3) {
    signal Capture3.captured(call Timer3.get());
  }
  default async event void Timer3.overflow() { }
  AVR_NONATOMIC_HANDLER(SIG_OVERFLOW3) {
    signal Timer3.overflow();
  }
}
