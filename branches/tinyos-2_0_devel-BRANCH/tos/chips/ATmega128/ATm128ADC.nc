/// $Id: ATm128ADC.nc,v 1.1.2.2 2005-02-09 02:11:06 mturon Exp $

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
