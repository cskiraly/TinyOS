/// $Id: HplAtm128Timer.nc,v 1.1.2.1 2006-01-15 23:44:54 scipio Exp $

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

/**
 * Basic interface to the hardware timers on an ATmega128.  
 * 
 * This interface is designed to be independent of whether the underlying 
 * hardware is an 8-bit or 16-bit wide counter.  As such, timer_size is 
 * specified via a generics parameter.  Because this is exposing a common 
 * subset of functionality that all ATmega128 hardware timers share, all 
 * that is exposed is access to the overflow capability.  Compare and capture
 * functionality are exposed on separate interfaces to allow easy 
 * configurability via wiring.
 *  
 * This interface provides four major groups of functionality:
 *      1) Timer Value: get/set current time
 *      2) Overflow Interrupt event
 *      3) Control of Overflow Interrupt: start/stop/clear...
 *      4) Timer Initialization: turn on/off clock source
 */
interface HplAtm128Timer<timer_size>
{
  /// Timer value register: Direct access
  async command timer_size get();
  async command void       set( timer_size t );

  /// Interrupt signals
  async event void overflow();        //<! Signalled on overflow interrupt

  /// Interrupt flag utilites: Bit level set/clr
  async command void reset(); //<! Clear the overflow interrupt flag
  async command void start(); //<! Enable the overflow interrupt
  async command void stop();  //<! Turn off overflow interrupts
  async command bool test();  //<! Did overflow interrupt occur?
  async command bool isOn();  //<! Is overflow interrupt on?

  /// Clock initialization interface
  async command void    off();                     //<! Turn off the clock 
  async command void    setScale( uint8_t scale);  //<! Turn on the clock
  async command uint8_t getScale();                //<! Get prescaler setting
}
