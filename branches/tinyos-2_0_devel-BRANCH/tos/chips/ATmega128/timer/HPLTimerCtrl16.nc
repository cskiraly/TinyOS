/// $Id: HPLTimerCtrl16.nc,v 1.1.2.1 2005-04-14 08:20:45 mturon Exp $

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

#include <ATm128Timer.h>

interface HPLTimerCtrl16
{
  /// Timer control registers: Direct access
  async command ATm128TimerCtrlCompare_t getCtrlCompare();
  async command ATm128TimerCtrlCapture_t getCtrlCapture();
  async command ATm128TimerCtrlClock_t   getCtrlClock();

  async command void setCtrlCompare( ATm128TimerCtrlCompare_t control );
  async command void setCtrlCapture( ATm128TimerCtrlCapture_t control );
  async command void setCtrlClock  ( ATm128TimerCtrlClock_t   control );

  /// Interrupt mask register: Direct access
  async command ATm128_ETIMSK_t getInterruptMask();
  async command void setInterruptMask( ATm128_ETIMSK_t mask);

  /// Interrupt flag register: Direct access
  async command ATm128_ETIFR_t getInterruptFlag();
  async command void setInterruptFlag( ATm128_ETIFR_t flags );
}

