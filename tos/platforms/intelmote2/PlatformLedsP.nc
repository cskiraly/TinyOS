/*
 * Copyright (c) 2005 Arched Rock Corporation 
 * All rights reserved. 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *	Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 *	Redistributions in binary form must reproduce the above copyright
 * notice, this list of conditions and the following disclaimer in the
 * documentation and/or other materials provided with the distribution.
 *  
 *   Neither the name of the Arched Rock Corporation nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE ARCHED
 * ROCK OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS
 * OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
 * TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
 * DAMAGE.
 */
/**
 * @author Philip Buonadonna
 */

includes hardware;

module PlatformLedsP {
  provides {
    interface GeneralIO as Led0;
    interface GeneralIO as Led1;
    interface GeneralIO as Led2;
  }
}

implementation {

  // Led 0
  async command void Led0.set(){_GPSR(103) |= _GPIO_bit(103);}
  async command void Led0.clr(){_GPCR(103) |= _GPIO_bit(103);}
  async command void Led0.toggle() {
    if (call Led0.get()) {
      call Led0.clr();
    }
    else {
      call Led0.set();
    }
    return;
  }
  async command bool Led0.get(){return ((_GPLR(103) & _GPIO_bit(103)) != 0);}
  async command void Led0.makeInput(){_GPIO_setaltfn(103,0);_GPDR(103) &= ~(_GPIO_bit(103));}
  async command void Led0.makeOutput(){_GPIO_setaltfn(103,0);_GPDR(103) |= _GPIO_bit(103);}

  // Led 1
  async command void Led1.set(){_GPSR(104) |= _GPIO_bit(104);}
  async command void Led1.clr(){_GPCR(104) |= _GPIO_bit(104);}
  async command void Led1.toggle() {
    if (call Led1.get()) {
      call Led1.clr();
    }
    else {
      call Led1.set();
    }
    return;
  }
  async command bool Led1.get(){return ((_GPLR(104) & _GPIO_bit(104)) != 0);}
  async command void Led1.makeInput(){_GPIO_setaltfn(104,0);_GPDR(104) &= ~(_GPIO_bit(104));}
  async command void Led1.makeOutput(){_GPIO_setaltfn(104,0);_GPDR(104) |= _GPIO_bit(104);}

  // Led 2
  async command void Led2.set(){_GPSR(105) |= _GPIO_bit(105);}
  async command void Led2.clr(){_GPCR(105) |= _GPIO_bit(105);}
  async command void Led2.toggle() {
    if (call Led2.get()) {
      call Led2.clr();
    }
    else {
      call Led2.set();
    }
    return;
  }
  async command bool Led2.get(){return ((_GPLR(105) & _GPIO_bit(105)) != 0);}
  async command void Led2.makeInput(){_GPIO_setaltfn(105,0);_GPDR(105) &= ~(_GPIO_bit(105));}
  async command void Led2.makeOutput(){_GPIO_setaltfn(105,0);_GPDR(105) |= _GPIO_bit(105);}

}

