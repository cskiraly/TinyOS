/// $Id: PlatformM.nc,v 1.1.2.4 2005-04-21 07:37:47 mturon Exp $

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

includes hardware;

module PlatformM
{
  provides interface Init;
  uses interface HPLUART as UART;
}
implementation
{
  void power_init() {
      atomic {
	  outw(MCUCR, 0);    // Internal RAM, IDLE, rupt vector at 0x0002
	  sbi(MCUCR, SE);    // enable sleep instruction!
      }
  }

  command error_t Init.init()
  {
    TOSH_SET_PIN_DIRECTIONS();
    //timer_init();  // Initialized by system timer in HALAlarm...
    power_init();
    call UART.init();

    return SUCCESS;
  }

  /** That serial library uses HPLUART as the common interface is no fun. */
  async event error_t UART.get(uint8_t data) { return SUCCESS; }
  async event error_t UART.putDone()         { return SUCCESS; }
}

