/// $Id: ATm128Timer16.nc,v 1.1.2.1 2005-01-20 04:17:32 mturon Exp $

/**
 * Copyright (c) 2004-2005 Crossbow Technology, Inc.  All rights reserved.
 *
 * Permission to use, copy, modify and distribute, this software and 
 * documentation is granted, provided the following conditions are met:
 *   1. The above copyright notice and these conditions, along with the 
 *      following disclaimers, appear in all copies of the software.
 *   2. When the use, copying, modification or distribution is for COMMERCIAL 
 *      purposes (i.e., any use other than academic research), then the 
 *      software (including all modifications of the software) may be used 
 *      ONLY with hardware manufactured by and purchased from Crossbow 
 *      Technology, unless you obtain separate written permission from, 
 *      and pay appropriate fees to, Crossbow. For example, no right to copy 
 *      and use the software on non-Crossbow hardware, if the use is 
 *      commercial in nature, is permitted under this license. 
 *   3. When the use, copying, modification or distribution is for 
 *      NON-COMMERCIAL PURPOSES (i.e., academic research use only), the 
 *      software may be used, whether or not with Crossbow hardware, without 
 *      any fee to Crossbow. 
 * 
 * IN NO EVENT SHALL CROSSBOW TECHNOLOGY OR ANY OF ITS LICENSORS BE LIABLE TO 
 * ANY PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL 
 * DAMAGES ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN
 * IF CROSSBOW OR ITS LICENSOR HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH 
 * DAMAGE. CROSSBOW TECHNOLOGY AND ITS LICENSORS SPECIFICALLY DISCLAIM ALL 
 * WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF 
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE SOFTWARE PROVIDED
 * HEREUNDER IS ON AN "AS IS" BASIS, AND NEITHER CROSSBOW NOR ANY LICENSOR HAS
 * ANY OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR 
 * MODIFICATIONS.
 */

/// @author Martin Turon <mturon@xbow.com>

includes ATm128Timer;

interface ATm128Timer16
{
  /// Timer value register: Direct access
  async command uint16_t get();
  async command void set(uint16_t t);

  /// Compare registers: Direct access
  async command uint16_t getCompareA();
  async command void setCompareA(uint16_t t);
  async command uint16_t getCompareB();
  async command void setCompareB(uint16_t t);
  async command uint16_t getCompareB();
  async command void setCompareB(uint16_t t);

  /// Capture register: Direct access
  async command uint16_t getCapture();
  async command void setCapture(uint16_t t);

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

  /// Interrupt signal
  async event void overflow();
  async event void firedA();
  async event void firedB();
  async event void firedC();
  async event void captured(uint16_t time);
}


