/// $Id: ATm128Timer8.nc,v 1.1.2.2 2005-01-21 09:27:32 mturon Exp $

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

interface ATm128Timer8
{
  /// Timer value register: Direct access
  async command uint8_t get();
  async command void set(uint8_t t);

  /// Compare register: Direct access
  async command uint8_t getCompare();
  async command void setCompare(uint8_t t);

  /// Timer control register: Direct access
  async command ATm128Timer8Control_t getControl();
  async command void setControl( ATm128Timer8Control_t control );

  /// Interrupt mask register: Direct access
  async command ATm128_TIMSK_t getInterruptMask();
  async command void setInterruptMask( ATm128_TIMSK_t mask);

  /// Interrupt flag register: Direct access
  async command ATm128_TIFR_t getInterruptFlags();
  async command void setInterruptFlags( ATm128_TIFR_t flags );

  /// Interrupt signals
  async event void overflow();        //<! Signalled on overflow interrupt
  async event void fired();           //<! Signalled on compare interrupt

  /// Interrupt flag utilites: Bit level set/clr
  async command void resetCompare();  //<! Clear the compare interrupt flag
  async command void startCompare();  //<! Enable the compare interrupt
  async command void stopCompare();   //<! Turn off compare interrupts
  async command bool testCompare();   //<! Did compare interrupt occur?
  async command bool checkCompare();  //<! Is compare interrupt on?

  async command void resetOverflow(); //<! Clear the overflow interrupt flag
  async command void startOverflow(); //<! Enable the overflow interrupt
  async command void stopOverflow();  //<! Turn off overflow interrupts
  async command bool testOverflow();  //<! Did overflow interrupt occur?
  async command bool checkOverflow(); //<! Is overflow interrupt on?
}
