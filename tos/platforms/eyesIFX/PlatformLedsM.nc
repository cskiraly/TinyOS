/*
 * Copyright (c) 2004, Technische Universitat Berlin
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright notice,
 *   this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the distribution.
 * - Neither the name of the Technische Universitat Berlin nor the names
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
 *
 * - Description ----------------------------------------------------------
 * Positive logic of LEDs on eyes platform requires set to be interpreted 
 *  opposite to turning it on.
 * - Revision -------------------------------------------------------------
 * $Revision: 1.1.2.1 $
 * $Date: 2005-05-24 17:14:47 $
 * @author Kevin Klues
 * ========================================================================
 */
 
module PlatformLedsM 
{
  provides interface GeneralIO as Led0;
  provides interface GeneralIO as Led1;
  provides interface GeneralIO as Led2;
  provides interface GeneralIO as Led3;
  
  uses interface GeneralIO as Led0Impl;
  uses interface GeneralIO as Led1Impl;
  uses interface GeneralIO as Led2Impl;
  uses interface GeneralIO as Led3Impl;  
}
implementation
{  
  async command void Led0.set() {call Led0Impl.clr();}
  async command void Led0.clr() {call Led0Impl.set();}
  async command void Led0.toggle() {call Led0Impl.toggle();}
  async command bool Led0.get() {return !(call Led0Impl.get());}
  async command void Led0.makeInput() {call Led0Impl.makeInput();}
  async command void Led0.makeOutput() {call Led0Impl.makeOutput();}
  
  async command void Led1.set() {call Led1Impl.clr();}
  async command void Led1.clr() {call Led1Impl.set();}
  async command void Led1.toggle() {call Led1Impl.toggle();}
  async command bool Led1.get() {return !(call Led1Impl.get());}
  async command void Led1.makeInput() {call Led1Impl.makeInput();}
  async command void Led1.makeOutput() {call Led1Impl.makeOutput();}
  
  async command void Led2.set() {call Led2Impl.clr();}
  async command void Led2.clr() {call Led2Impl.set();}
  async command void Led2.toggle() {call Led2Impl.toggle();}
  async command bool Led2.get() {return !(call Led2Impl.get());}
  async command void Led2.makeInput() {call Led2Impl.makeInput();}
  async command void Led2.makeOutput() {call Led2Impl.makeOutput();}
  
  async command void Led3.set() {call Led3Impl.clr();}
  async command void Led3.clr() {call Led3Impl.set();}
  async command void Led3.toggle() {call Led3Impl.toggle();}
  async command bool Led3.get() {return !(call Led3Impl.get());}
  async command void Led3.makeInput() {call Led3Impl.makeInput();}
  async command void Led3.makeOutput() {call Led3Impl.makeOutput();} 
}
