// $Id: LedsM.nc,v 1.1.2.2 2005-03-16 08:13:33 jpolastre Exp $

/*									tab:4
 * "Copyright (c) 2000-2005 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 */

/**
 * @author Joe Polastre
 */

module LedsM {
  provides {
    interface Init;
    interface Leds;
  }
  uses {
    interface GeneralIO as Led1;
    interface GeneralIO as Led2;
    interface GeneralIO as Led3;
  }
}
implementation
{
  #define dbg(n,msg)

  command error_t Init.init() {
    atomic {
      dbg(DBG_BOOT, "LEDS: initialized.\n");
      call Led1.makeOutput();
      call Led2.makeOutput();
      call Led3.makeOutput();
      call Led1.set();
      call Led2.set();
      call Led3.set();
    }
    return SUCCESS;
  }

  async command void Leds.led1On() {
    dbg(DBG_LED, "LEDS: Led1 on.\n");
    call Led1.clr();
  }

  async command void Leds.led1Off() {
    dbg(DBG_LED, "LEDS: Led1 off.\n");
    call Led1.set();
  }

  async command void Leds.led1Toggle() {
    call Led1.toggle();
    // this should be removed by dead code elimination when compiled for
    // the physical motes
    if (call Led1.get())
      dbg(DBG_LED, "LEDS: Led1 off.\n");
    else
      dbg(DBG_LED, "LEDS: Led1 on.\n");
  }

  async command void Leds.led2On() {
    dbg(DBG_LED, "LEDS: Led2 on.\n");
    call Led2.clr();
  }

  async command void Leds.led2Off() {
    dbg(DBG_LED, "LEDS: Led2 off.\n");
    call Led2.set();
  }

  async command void Leds.led2Toggle() {
    call Led2.toggle();
    if (call Led2.get())
      dbg(DBG_LED, "LEDS: Led2 off.\n");
    else
      dbg(DBG_LED, "LEDS: Led2 on.\n");
  }

  async command void Leds.led3On() {
    dbg(DBG_LED, "LEDS: Led3 on.\n");
    call Led3.clr();
  }

  async command void Leds.led3Off() {
    dbg(DBG_LED, "LEDS: Led3 off.\n");
    call Led3.set();
  }

  async command void Leds.led3Toggle() {
    call Led3.toggle();
    if (call Led3.get())
      dbg(DBG_LED, "LEDS: Led3 off.\n");
    else
      dbg(DBG_LED, "LEDS: Led3 on.\n");
  }

  async command error_t Leds.redOn() {
    call Leds.led1On();
    return SUCCESS;
  }

  async command error_t Leds.redOff() {
    dbg(DBG_LED, "LEDS: Red off.\n");
    call Leds.led1Off();
    return SUCCESS;
  }

  async command error_t Leds.redToggle() {
    call Leds.led1Toggle();
    return SUCCESS;
  }

  async command error_t Leds.greenOn() {
    dbg(DBG_LED, "LEDS: Green on.\n");
    call Leds.led2On();
    return SUCCESS;
  }

  async command error_t Leds.greenOff() {
    dbg(DBG_LED, "LEDS: Green off.\n");
    call Leds.led2Off();
    return SUCCESS;
  }

  async command error_t Leds.greenToggle() {
    call Leds.led2Toggle();
    return SUCCESS;
  }

  async command error_t Leds.yellowOn() {
    dbg(DBG_LED, "LEDS: Yellow on.\n");
    call Leds.led3On();
    return SUCCESS;
  }

  async command error_t Leds.yellowOff() {
    dbg(DBG_LED, "LEDS: Yellow off.\n");
    call Leds.led3Off();
    return SUCCESS;
  }

  async command error_t Leds.yellowToggle() {
    call Leds.led3Toggle();
    return SUCCESS;
  }
  
  async command uint8_t Leds.get() {
    uint8_t rval;
    atomic {
      rval = 0;
      if (call Led1.get())
	rval |= 0x01 << 0;
      if (call Led2.get())
	rval |= 0x01 << 1;
      if (call Led3.get())
	rval |= 0x01 << 2;
    }
    return rval;
  }
  
  async command error_t Leds.set(uint8_t ledsNum) {
    uint8_t ledsOn;
    atomic {
      ledsOn = (ledsNum & 0x7);
      if (ledsOn >> 0 & 0x01)
	call Leds.led1On();
      else
	call Leds.led1Off();
      if (ledsOn >> 1 & 0x01) 
	call Leds.led2On();
      else 
	call Leds.led2Off();
      if (ledsOn >> 2 & 0x01) 
	call Leds.led3On();
      else 
	call Leds.led3Off();
    }
    return SUCCESS;
  }
}
