/// $Id: HALTimerM.nc,v 1.1.2.1 2005-02-09 18:53:11 mturon Exp $

/**
 * Copyright (c) 2004-2005 Crossbow Technology, Inc.  All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without 
 * modification, are permitted provided that the following conditions 
 * are met:
 * - Redistributions of source code must retain the above copyright notice,
 *   this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright 
 *   notice, this list of conditions and the following disclaimer in the 
 *   documentation and/or other materials provided with the distribution.
 * - Neither the name of the Technische Universitaet Berlin nor the names 
 *   of its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS 
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT 
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT 
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, 
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED 
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, 
 * OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY 
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT 
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE 
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/// @author Martin Turon <mturon@xbow.com>

/** 
 * Abstract hardware platform layer (HPL) interfaces into genric 
 * hardware abstraction layer (HAL) interfaces of arbitrary bit width.
 * See TEP 102.
 */ 
module HALTimerM
{
  provides {
      // 8-bit Timers
      interface HALTimer<uint8_t> as Timer0;
      interface HALCompare<uint8_t> as Compare0;

      interface HALTimer<uint8_t> as Timer2;
      interface HALCompare<uint8_t> as Compare2;

      // 16-bit Timers
      interface HALTimer<uint16_t> as Timer1;
      interface HALCompare<uint16_t> as Compare1A;
      interface HALCompare<uint16_t> as Compare1B;
      interface HALCompare<uint16_t> as Compare1C;

      interface HALTimer<uint8_t> as Timer3;
      interface HALCompare<uint16_t> as Compare3A;
      interface HALCompare<uint16_t> as Compare3B;
      interface HALCompare<uint16_t> as Compare3C;
  }
  uses {
      interface ATm128Timer8 as HPLTimer0;
      interface ATm128Timer8 as HPLTimer2;

      interface ATm128Timer16 as HPLTimer1;
      interface ATm128Timer16Compare as HPLCompare1A;
      interface ATm128Timer16Compare as HPLCompare1B;
      interface ATm128Timer16Compare as HPLCompare1C;

      interface ATm128Timer16 as HPLTimer3;
      interface ATm128Timer16Compare as HPLCompare1A;
      interface ATm128Timer16Compare as HPLCompare1B;
      interface ATm128Timer16Compare as HPLCompare1C;
  }
}
implementation
{
  //=== Read the current timer value. ===================================
  async command uint8_t  Timer0.get() { return HPLTimer0.get(); }
  async command uint8_t  Timer2.get() { return HPLTimer2.get(); }
  async command uint16_t Timer1.get() { return HPLTimer1.get(); }
  async command uint16_t Timer3.get() { return HPLTimer3.get(); }

  //=== Set/clear the current timer value. ==============================
  async command void Timer0.set(uint8_t t) { HPLTimer0.set(t); }
  async command void Timer2.set(uint8_t t) { HPLTimer2.set(t); }
  async command void Timer1.set(uint16_t t) { HPLTimer1.set(t); }
  async command void Timer3.set(uint16_t t) { HPLTimer3.set(t); }

  //=== Interrupt bit utilities. ======================================
  async command void Timer0.reset()   { HPLTimer0.resetOverflow(); }
  async command void Timer0.start()   { HPLTimer0.startOverflow(); }
  async command void Timer0.stop()    { HPLTimer0.stopOverflow(); }
  async command void Timer0.test()    { HPLTimer0.testOverflow(); }
  async command void Timer0.isOn()    { HPLTimer0.checkOverflow(); }

  async command void Timer2.reset()   { HPLTimer2.resetOverflow(); }
  async command void Timer2.start()   { HPLTimer2.startOverflow(); }
  async command void Timer2.stop()    { HPLTimer2.stopOverflow(); }
  async command void Timer2.test()    { HPLTimer2.testOverflow(); }
  async command void Timer2.isOn()    { HPLTimer2.checkOverflow(); }

  async command void Timer1.reset()   { HPLTimer1.resetOverflow(); }
  async command void Timer1.start()   { HPLTimer1.startOverflow(); }
  async command void Timer1.stop()    { HPLTimer1.stopOverflow(); }
  async command void Timer1.test()    { HPLTimer1.testOverflow(); }
  async command void Timer1.isOn()    { HPLTimer1.checkOverflow(); }

  async command void Timer3.reset()   { HPLTimer3.resetOverflow(); }
  async command void Timer3.start()   { HPLTimer3.startOverflow(); }
  async command void Timer3.stop()    { HPLTimer3.stopOverflow(); }
  async command void Timer3.test()    { HPLTimer3.testOverflow(); }
  async command void Timer3.isOn()    { HPLTimer3.checkOverflow(); }

  async command void Compare0.reset() { HPLTimer0.resetCompare(); }
  async command void Compare0.start() { HPLTimer0.startCompare(); }
  async command void Compare0.stop()  { HPLTimer0.stopCompare(); }

  async command void Compare2.reset() { HPLTimer2.resetCompare(); }
  async command void Compare2.start() { HPLTimer2.startCompare(); }
  async command void Compare2.stop()  { HPLTimer2.stopCompare(); }

  async command uint16_t Compare1A.get()     { return HPLCompare1A.get(); }
  async command void Compare1A.set(uint16_t) { HPLCompare1A.set(t); }
  async command void Compare1A.reset()       { HPLCompare1A.reset(); }
  async command void Compare1A.reset()       { HPLCompare1A.reset(); }
  async command void Compare1A.start()       { HPLCompare1A.start(); }
  async command void Compare1A.stop()        { HPLCompare1A.stop(); }
  async command bool Compare1A.test()        { return HPLCompare1A.test(); }
  async command bool Compare1A.isOn()        { return HPLCompare1A.isOn(); }

  async command uint16_t Compare1B.get()     { return HPLCompare1B.get(); }
  async command void Compare1B.set(uint16_t) { HPLCompare1B.set(t); }
  async command void Compare1B.reset()       { HPLCompare1B.reset(); }
  async command void Compare1B.reset()       { HPLCompare1B.reset(); }
  async command void Compare1B.start()       { HPLCompare1B.start(); }
  async command void Compare1B.stop()        { HPLCompare1B.stop(); }
  async command bool Compare1B.test()        { return HPLCompare1B.test(); }
  async command bool Compare1B.isOn()        { return HPLCompare1B.isOn(); }

  async command uint16_t Compare1C.get()     { return HPLCompare1C.get(); }
  async command void Compare1C.set(uint16_t) { HPLCompare1C.set(t); }
  async command void Compare1C.reset()       { HPLCompare1C.reset(); }
  async command void Compare1C.reset()       { HPLCompare1C.reset(); }
  async command void Compare1C.start()       { HPLCompare1C.start(); }
  async command void Compare1C.stop()        { HPLCompare1C.stop(); }
  async command bool Compare1C.test()        { return HPLCompare1C.test(); }
  async command bool Compare1C.isOn()        { return HPLCompare1C.isOn(); }


  async command uint16_t Compare3A.get()     { return HPLCompare3A.get(); }
  async command void Compare3A.set(uint16_t) { HPLCompare3A.set(t); }
  async command void Compare3A.reset()       { HPLCompare3A.reset(); }
  async command void Compare3A.reset()       { HPLCompare3A.reset(); }
  async command void Compare3A.start()       { HPLCompare3A.start(); }
  async command void Compare3A.stop()        { HPLCompare3A.stop(); }
  async command bool Compare3A.test()        { return HPLCompare3A.test(); }
  async command bool Compare3A.isOn()        { return HPLCompare3A.isOn(); }

  async command uint16_t Compare3B.get()     { return HPLCompare3B.get(); }
  async command void Compare3B.set(uint16_t) { HPLCompare3B.set(t); }
  async command void Compare3B.reset()       { HPLCompare3B.reset(); }
  async command void Compare3B.reset()       { HPLCompare3B.reset(); }
  async command void Compare3B.start()       { HPLCompare3B.start(); }
  async command void Compare3B.stop()        { HPLCompare3B.stop(); }
  async command bool Compare3B.test()        { return HPLCompare3B.test(); }
  async command bool Compare3B.isOn()        { return HPLCompare3B.isOn(); }

  async command uint16_t Compare3C.get()     { return HPLCompare3C.get(); }
  async command void Compare3C.set(uint16_t) { HPLCompare3C.set(t); }
  async command void Compare3C.reset()       { HPLCompare3C.reset(); }
  async command void Compare3C.reset()       { HPLCompare3C.reset(); }
  async command void Compare3C.start()       { HPLCompare3C.start(); }
  async command void Compare3C.stop()        { HPLCompare3C.stop(); }
  async command bool Compare3C.test()        { return HPLCompare3C.test(); }
  async command bool Compare3C.isOn()        { return HPLCompare3C.isOn(); }


  //=== Timer interrupts signals ========================================
  default async event void HPLTimer0.fired() { signal Compare0.fired(); }
  default async event void HPLTimer0.overflow() { signal Timer0.fired(); }

  default async event void HPLTimer2.fired() { signal Compare2.fired(); }
  default async event void HPLTimer2.overflow() { signal Timer2.fired(); }

  default async event void HPLTimer1.overflow() { signal Timer1.fired(); }
  default async event void HPLCompare1A.fired() { signal Compare1A.fired(); }
  default async event void HPLCompare1B.fired() { signal Compare1B.fired(); }
  default async event void HPLCompare1C.fired() { signal Compare1C.fired(); }

  default async event void HPLTimer3.overflow() { signal Timer3.fired(); }
  default async event void HPLCompare3A.fired() { signal Compare3A.fired(); }
  default async event void HPLCompare3B.fired() { signal Compare3B.fired(); }
  default async event void HPLCompare3C.fired() { signal Compare3C.fired(); }
}

