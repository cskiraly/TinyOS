/// $Id: ATm128Timer16.nc,v 1.1.2.2 2005-01-21 09:27:32 mturon Exp $

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
  async command void     set(uint16_t t);

  /// Compare registers: Direct access
  async command uint16_t getCompareA();
  async command uint16_t getCompareB();
  async command uint16_t getCompareC();
  async command void     setCompareA(uint16_t t);
  async command void     setCompareB(uint16_t t);
  async command void     setCompareC(uint16_t t);

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
  async event void firedA();          //<! Signalled on compareA interrupt
  async event void firedB();          //<! Signalled on compareB interrupt
  async event void firedC();          //<! Signalled on compareC interrupt
  async event void captured(uint16_t time);

  /// Interrupt flag utilites: Bit level set/clr
  async command void resetCapture();  //<! Clear the capture interrupt flag
  async command void resetCompareA(); //<! Clear the compareA interrupt flag
  async command void resetCompareB(); //<! Clear the compareB interrupt flag
  async command void resetCompareC(); //<! Clear the compareC interrupt flag
  async command void resetOverflow(); //<! Clear the overflow interrupt flag

  async command void startCapture();  //<! Enable the capture interrupt
  async command void startCompareA(); //<! Enable the compareA interrupt
  async command void startCompareB(); //<! Enable the compareB interrupt
  async command void startCompareC(); //<! Enable the compareC interrupt
  async command void startOverflow(); //<! Enable the overflow interrupt

  async command void stopCapture();   //<! Turn off capture interrupts
  async command void stopCompareA();  //<! Turn off compareA interrupts
  async command void stopCompareB();  //<! Turn off compareB interrupts
  async command void stopCompareC();  //<! Turn off compareC interrupts
  async command void stopOverflow();  //<! Turn off overflow interrupts

  async command bool testCapture();   //<! Did capture interrupt occur?
  async command bool testCompareA();  //<! Did compareA interrupt occur?
  async command bool testCompareB();  //<! Did compareB interrupt occur?
  async command bool testCompareC();  //<! Did compareC interrupt occur?
  async command bool testOverflow();  //<! Did overflow interrupt occur?

  async command bool checkCapture();  //<! Is capture interrupt on?
  async command bool checkCompareA(); //<! Is compareA interrupt on?
  async command bool checkCompareB(); //<! Is compareB interrupt on?
  async command bool checkCompareC(); //<! Is compareC interrupt on?
  async command bool checkOverflow(); //<! Is overflow interrupt on?
}

