/// $Id: ATm128Timer16.nc,v 1.1.2.4 2005-02-09 02:11:06 mturon Exp $

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

includes ATm128Timer;

interface ATm128Timer16
{
  /// Timer value register: Direct access
  async command uint16_t get();
  async command void     set(uint16_t t);

  /// Capture register: Direct access
  async command uint16_t getCapture();
  async command void     setCapture(uint16_t t);

  /// Timer control registers: Direct access
  async command ATm128TimerCtrlCapture_t getCtrlCompare();
  async command ATm128TimerCtrlCompare_t getCtrlCapture();
  async command ATm128TimerCtrlClock_t getCtrlClock();

  async command void setCtrlCompare( ATm128TimerCtrlCapture_t control );
  async command void setCtrlCapture( ATm128TimerCtrlCompare_t control );
  async command void setCtrlClock  ( ATm128TimerCtrlClock_t control );

  /// Interrupt mask register: Direct access
  async command ATm128_ETIMSK_t getInterruptMask();
  async command void setInterruptMask( ATm128_ETIMSK_t mask);

  /// Interrupt flag register: Direct access
  async command ATm128_ETIFR_t getInterruptFlags();
  async command void setInterruptFlags( ATm128_ETIFR_t flags );

  /// Interrupt signals
  async event void overflow();        //<! Signalled on overflow interrupt
  async event void captured(uint16_t time);

  /// Interrupt flag utilites: Bit level set/clr
  async command void resetCapture();  //<! Clear the capture interrupt flag
  async command void resetOverflow(); //<! Clear the overflow interrupt flag

  async command void startCapture();  //<! Enable the capture interrupt
  async command void startOverflow(); //<! Enable the overflow interrupt

  async command void stopCapture();   //<! Turn off capture interrupts
  async command void stopOverflow();  //<! Turn off overflow interrupts

  async command bool testCapture();   //<! Did capture interrupt occur?
  async command bool testOverflow();  //<! Did overflow interrupt occur?

  async command bool checkCapture();  //<! Is capture interrupt on?
  async command bool checkOverflow(); //<! Is overflow interrupt on?
}

