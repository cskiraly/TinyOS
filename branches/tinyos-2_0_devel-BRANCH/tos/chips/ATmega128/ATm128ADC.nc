/// $Id: ATm128ADC.nc,v 1.1.2.1 2005-02-03 01:16:07 mturon Exp $

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

includes ATm128ADC;

interface ATm128ADC
{
  /// ADC selection register: Direct access
  async command ATm128ADCSelect_t getSelect();
  async command void setSelect( ATm128ADCControl_t select );

  /// ADC control register: Direct access
  async command ATm128ADCControl_t getControl();
  async command void setControl( ATm128ADCControl_t control );

  /// ADC data register: Direct access
  async command uint16_t getValue();

  /// Timer value register: Direct access
  command result_t bind(MSP430ADC12Settings_t settings);

  async command result_t reserve();
  async command result_t reserveRepeat(uint16_t jiffies);
  async command result_t unreserve();

  /// Interrupt flag utilites: Bit level set/clr
  async command void enable();         //<! Enable ADC sampling
  async command void disable();        //<! Disable ADC sampling
  async command void start();          //<! Start ADC conversion
  async command void stop();           //<! Stop ADC conversion
  async command void setContinuous();  //<! Enable continuous sampling
  async command void setSingle();      //<! Disable continuous sampling
  async command void reset();          //<! Clear the ADC interrupt flag
  async command bool isComplete();     //<! Did ADC interrupt occur?
  async command bool isStarted();      //<! Is ADC started on?
  async command bool isEnabled();      //<! Is ADC started on?

  /// Split-phase interface to ADC data
  async command uint8_t getData();
  async command uint8_t getDataRepeat(uint16_t jiffies);   

  async event result_t dataReady(uint16_t data);     
}
