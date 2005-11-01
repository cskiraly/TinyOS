// $Id: HplPXA27xGPIOIntM.nc,v 1.1.2.1 2005-10-27 22:52:25 philipb Exp $

/*									tab:4
 *  IMPORTANT: READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.  By
 *  downloading, copying, installing or using the software you agree to
 *  this license.  If you do not agree to this license, do not download,
 *  install, copy or use the software.
 *
 *  Intel Open Source License 
 *
 *  Copyright (c) 2002 Intel Corporation 
 *  All rights reserved. 
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions are
 *  met:
 * 
 *	Redistributions of source code must retain the above copyright
 *  notice, this list of conditions and the following disclaimer.
 *	Redistributions in binary form must reproduce the above copyright
 *  notice, this list of conditions and the following disclaimer in the
 *  documentation and/or other materials provided with the distribution.
 *      Neither the name of the Intel Corporation nor the names of its
 *  contributors may be used to endorse or promote products derived from
 *  this software without specific prior written permission.
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
 * 
 */

//@author Phil Buonadonna
module PXA27XGPIOIntM {

  provides {
    interface StdControl;
    interface PXA27XGPIOInt[uint8_t pin];
  }
  uses {
    interface PXA27XInterrupt as GPIOIrq;   // GPIO 2 - 120 only
    interface PXA27XInterrupt as GPIOIrq0;
    interface PXA27XInterrupt as GPIOIrq1;
  }
}

implementation {

  bool gfInitialized = FALSE;

  command result_t StdControl.init() {
    bool isInited;
    atomic {
      isInited = gfInitialized;
      gfInitialized = TRUE;
    }

    if (!isInited) {
      call GPIOIrq0.allocate();
      call GPIOIrq1.allocate();
      call GPIOIrq.allocate();
    }

    return SUCCESS;
  }

  command result_t StdControl.start() {
    call GPIOIrq0.enable();
    call GPIOIrq1.enable();
    call GPIOIrq.enable();
    return SUCCESS;
  }

  command result_t StdControl.stop() {

    return SUCCESS;
  }


  async command void PXA27XGPIOInt.enable[uint8_t pin](uint8_t mode)
  {
    if (pin < 121) {
      switch (mode) {
      case TOSH_RISING_EDGE:
	_GRER(pin) |= _GPIO_bit(pin);
	_GFER(pin) &= ~(_GPIO_bit(pin));
	break;
      case TOSH_FALLING_EDGE:
	_GRER(pin) &= ~(_GPIO_bit(pin));
	_GFER(pin) |= _GPIO_bit(pin);
	break;
      case TOSH_BOTH_EDGE:
	_GRER(pin) |= _GPIO_bit(pin);	
	_GFER(pin) |= _GPIO_bit(pin);
	break;
      default:
	break;
      }
    }
    return;
  }


  async command void PXA27XGPIOInt.disable[uint8_t pin]() 
  {
    if (pin < 121) {
      _GRER(pin) &= ~(_GPIO_bit(pin));
      _GFER(pin) &= ~(_GPIO_bit(pin));
    }

    return;
  }

  async command void PXA27XGPIOInt.clear[uint8_t pin]()
  {
    if (pin < 121) {
      _GEDR(pin) = _GPIO_bit(pin);
    }
    
    return;
  }

  default async event void PXA27XGPIOInt.fired[uint8_t pin]() 
  {
    return;
  }


  async event void GPIOIrq.fired() 
  {

    uint32_t DetectReg;
    uint8_t pin;

    // Mask off GPIO 0 and 1 (handled by direct IRQs)
    atomic DetectReg = (GEDR0 & ~((1<<1) | (1<<0))); 

    while (DetectReg) {
      pin = 31 - _pxa27x_clzui(DetectReg);
      signal PXA27XGPIOInt.fired[pin]();
      DetectReg &= ~(1 << pin);
    }

    atomic DetectReg = GEDR1;

    while (DetectReg) {
      pin = 31 - _pxa27x_clzui(DetectReg);
      signal PXA27XGPIOInt.fired[(pin+32)]();
      DetectReg &= ~(1 << pin);
    }

    atomic DetectReg = GEDR2;

    while (DetectReg) {
      pin = 31 - _pxa27x_clzui(DetectReg);
      signal PXA27XGPIOInt.fired[(pin+64)]();
      DetectReg &= ~(1 << pin);
    }

    atomic DetectReg = GEDR3;

    while (DetectReg) {
      pin = 31 - _pxa27x_clzui(DetectReg);
      signal PXA27XGPIOInt.fired[(pin+96)]();
      DetectReg &= ~(1 << pin);
    }

    return;
  }

  async event void GPIOIrq0.fired()
  {
    signal PXA27XGPIOInt.fired[0]();
  }

  async event void GPIOIrq1.fired() 
  {
    signal PXA27XGPIOInt.fired[1]();
  } 

}
