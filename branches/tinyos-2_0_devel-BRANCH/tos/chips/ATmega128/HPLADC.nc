/// $Id: HPLADC.nc,v 1.1.2.1 2005-03-24 08:47:40 husq Exp $

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
/// @author Hu Siquan <husq@xbow.com>

includes ATm128ADC;

interface HPLADC
{
  /// ADC selection register: Direct access
  async command ATm128ADCSelection_t getSelection();
  async command void setSelection( ATm128ADCSelection_t selection );

  /// ADC control register: Direct access
  async command ATm128ADCControl_t getControl();
  async command void setControl( ATm128ADCControl_t control );

  /// ADC data register: Direct access
  async command uint16_t getValue();

  /// Interrupt flag utilites: Bit level set/clr
  async command void enableADC();         //<! Enable ADC sampling
  async command void disableADC();        //<! Disable ADC sampling
  async command void startConversion();          //<! Start ADC conversion
  async command void stopConversion();           //<! Stop ADC conversion
  async command void enableInterruption()        //<! Enable ADC Interruption
  async command void disableInterruption()       //<! Disable ADC Interruption
  async command void setContinuous();  //<! Enable continuous sampling
  async command void setSingle();      //<! Disable continuous sampling
  async command void reset();          //<! Clear the ADC interrupt flag
  async command bool isComplete();     //<! Did ADC interrupt occur?
  async command bool isStarted();      //<! Is ADC started on?
  async command bool isEnabled();      //<! Is ADC enabled?
  async command void setPrescaler(uint8_t scale);  //<! Set ADC prescaler selection bits

  /**
   * Signaled when a data ready is ready.
   *
   * @return SUCCESS always.
   */
  async event result_t dataReady(uint16_t data);     
}
