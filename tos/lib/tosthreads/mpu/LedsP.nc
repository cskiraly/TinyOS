/*
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
 * The implementation of the standard 3 LED mote abstraction.
 * Adapted because LED 2 (red) is active high on SAM3U_EK.
 *
 * @author Joe Polastre
 * @author Philip Levis
 * @author Wanja Hofer <wanja@cs.fau.de>
 *
 * @date   March 21, 2005
 */

#include "syscall_ids.h"

module LedsP @safe() {
  provides {
    interface Init;
    interface Leds;
	interface LedsCallback;
  }
  uses {
    interface GeneralIO as Led0;
    interface GeneralIO as Led1;
    interface GeneralIO as Led2;
	interface SyscallInstruction;
  }
}
implementation {
  command error_t Init.init() {
    atomic {
      dbg("Init", "LEDS: initialized.\n");
      call Led0.makeOutput();
      call Led1.makeOutput();
      call Led2.makeOutput();
      call Led0.set();
      call Led1.set();
      call Led2.clr();
    }
    return SUCCESS;
  }

  async command void Leds.led0On() __attribute__((section(".textcommon"))) {
    (void) call SyscallInstruction.syscall(SYSCALL_ID_LEDS, (uint32_t) SYSCALL_LEDS_PARAM_ON, (uint32_t) SYSCALL_LEDS_PARAM_LED0, 0, 0);
  }
  async command void Leds.led0Off() __attribute__((section(".textcommon"))) {
    (void) call SyscallInstruction.syscall(SYSCALL_ID_LEDS, (uint32_t) SYSCALL_LEDS_PARAM_OFF, (uint32_t) SYSCALL_LEDS_PARAM_LED0, 0, 0);
  }
  async command void Leds.led0Toggle() __attribute__((section(".textcommon"))) {
    (void) call SyscallInstruction.syscall(SYSCALL_ID_LEDS, (uint32_t) SYSCALL_LEDS_PARAM_TOGGLE, (uint32_t) SYSCALL_LEDS_PARAM_LED0, 0, 0);
  }
  async command void Leds.led1On() __attribute__((section(".textcommon"))) {
    (void) call SyscallInstruction.syscall(SYSCALL_ID_LEDS, (uint32_t) SYSCALL_LEDS_PARAM_ON, (uint32_t) SYSCALL_LEDS_PARAM_LED1, 0, 0);
  }
  async command void Leds.led1Off() __attribute__((section(".textcommon"))) {
    (void) call SyscallInstruction.syscall(SYSCALL_ID_LEDS, (uint32_t) SYSCALL_LEDS_PARAM_OFF, (uint32_t) SYSCALL_LEDS_PARAM_LED1, 0, 0);
  }
  async command void Leds.led1Toggle() __attribute__((section(".textcommon"))) {
    (void) call SyscallInstruction.syscall(SYSCALL_ID_LEDS, (uint32_t) SYSCALL_LEDS_PARAM_TOGGLE, (uint32_t) SYSCALL_LEDS_PARAM_LED1, 0, 0);
  }
  async command void Leds.led2On() __attribute__((section(".textcommon"))) {
    (void) call SyscallInstruction.syscall(SYSCALL_ID_LEDS, (uint32_t) SYSCALL_LEDS_PARAM_ON, (uint32_t) SYSCALL_LEDS_PARAM_LED2, 0, 0);
  }
  async command void Leds.led2Off() __attribute__((section(".textcommon"))) {
    (void) call SyscallInstruction.syscall(SYSCALL_ID_LEDS, (uint32_t) SYSCALL_LEDS_PARAM_OFF, (uint32_t) SYSCALL_LEDS_PARAM_LED2, 0, 0);
  }
  async command void Leds.led2Toggle() __attribute__((section(".textcommon"))) {
    (void) call SyscallInstruction.syscall(SYSCALL_ID_LEDS, (uint32_t) SYSCALL_LEDS_PARAM_TOGGLE, (uint32_t) SYSCALL_LEDS_PARAM_LED2, 0, 0);
  }
  async command uint8_t Leds.get() __attribute__((section(".textcommon"))) {
    return (uint8_t) (call SyscallInstruction.syscall(SYSCALL_ID_LEDS, (uint32_t) SYSCALL_LEDS_PARAM_GET, 0, 0, 0));
  }
  async command void Leds.set(uint8_t val) __attribute__((section(".textcommon"))) {
    (void) call SyscallInstruction.syscall(SYSCALL_ID_LEDS, (uint32_t) SYSCALL_LEDS_PARAM_SET, (uint32_t) val, 0, 0);
  }

  /* Note: the call is inside the dbg, as it's typically a read of a volatile
     location, so can't be deadcode eliminated */
#define DBGLED(n) \
  dbg("LedsC", "LEDS: Led" #n " %s.\n", call Led ## n .get() ? "off" : "on");

  async command uint32_t LedsCallback.leds(uint32_t leds_function, uint32_t leds_param) {
    if (leds_function == SYSCALL_LEDS_PARAM_ON) {
	  if (leds_param == SYSCALL_LEDS_PARAM_LED0) {
        call Led0.clr();
        DBGLED(0);
	  } else if (leds_param == SYSCALL_LEDS_PARAM_LED1) {
        call Led1.clr();
        DBGLED(1);
	  } else if (leds_param == SYSCALL_LEDS_PARAM_LED2) {
        call Led2.set();
        DBGLED(2);
	  }
	} else if (leds_function == SYSCALL_LEDS_PARAM_OFF) {
	  if (leds_param == SYSCALL_LEDS_PARAM_LED0) {
        call Led0.set();
        DBGLED(0);
	  } else if (leds_param == SYSCALL_LEDS_PARAM_LED1) {
        call Led1.set();
        DBGLED(1);
	  } else if (leds_param == SYSCALL_LEDS_PARAM_LED2) {
        call Led2.clr();
        DBGLED(2);
	  }
	} else if (leds_function == SYSCALL_LEDS_PARAM_TOGGLE) {
	  if (leds_param == SYSCALL_LEDS_PARAM_LED0) {
        call Led0.toggle();
        DBGLED(0);
	  } else if (leds_param == SYSCALL_LEDS_PARAM_LED1) {
        call Led1.toggle();
        DBGLED(1);
	  } else if (leds_param == SYSCALL_LEDS_PARAM_LED2) {
        call Led2.toggle();
        DBGLED(2);
	  }
	} else if (leds_function == SYSCALL_LEDS_PARAM_GET) {
      uint8_t rval;
      atomic {
        rval = 0;
        if (!call Led0.get()) {
 	rval |= LEDS_LED0;
        }
        if (!call Led1.get()) {
  	rval |= LEDS_LED1;
        }
        if (call Led2.get()) {
  	rval |= LEDS_LED2;
        }
      }
	  return (uint32_t) rval;
	} else if (leds_function == SYSCALL_LEDS_PARAM_SET) {
	  uint8_t val = (uint8_t) leds_param;
      atomic {
        if (val & LEDS_LED0) {
  	call Leds.led0On();
        }
        else {
  	call Leds.led0Off();
        }
        if (val & LEDS_LED1) {
  	call Leds.led1On();
        }
        else {
  	call Leds.led1Off();
        }
        if (val & LEDS_LED2) {
  	call Leds.led2On();
        }
        else {
  	call Leds.led2Off();
        }
      }
	}
	return 0;
  }
}
