/// $Id: HplAtm128Adc.nc,v 1.1.2.1 2005-10-31 20:08:29 scipio Exp $

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

#include "Atm128Adc.h"

interface HplAtm128Adc {
  /// ADC selection register: Direct access
  async command Atm128Admux_t getAdmux();
  async command void setAdmux(Atm128Admux_t admux);

  /// ADC control register: Direct access
  async command Atm128Adcsra_t getAdcsra();
  async command void setAdcsra(Atm128Adcsra_t adcsra);

  /// ADC data register: Direct access
  async command uint16_t getValue();

  /// A/D control utilities. All of these clear any pending A/D interrupt.
  async command void enableAdc();         //<! Enable ADC sampling
  async command void disableAdc();        //<! Disable ADC sampling

  async command void enableInterruption();//<! Enable ADC Interruption
  async command void disableInterruption();//<! Disable ADC Interruption

  async command void resetInterrupt();    //<! Clear the ADC interrupt flag
  async command void startConversion();   //<! Start ADC conversion
  async command void setContinuous();     //<! Enable continuous sampling
  async command void setSingle();         //<! Disable continuous sampling

  /* A/D status checks */
  async command bool isEnabled();         //<! Is ADC enabled?
  async command bool isStarted();         //<! A/D conversion in progress?
  async command bool isComplete();        //<! A/D conversion complete?
  					  //   (cleared when interrupt taken)

  async command void setPrescaler(uint8_t scale);  //<! Set ADC prescaler selection bits

  /**
   * Cancel A/D conversion and any pending A/D interrupt. Also disables the
   * ADC interruption (otherwise a sample might start at the next sleep
   * instruction). This command can assume that the A/D converter is enabled. 
   * @return TRUE if an A/D conversion was in progress or an A/D interrupt
   *   was pending, FALSE otherwise. In single conversion mode, a return
   *   of TRUE implies that the dataReady event will not be signaled.
   */
  async command bool cancel();

  /**
   * A/D interrupt occured
   * @param data Latest A/D conversion result
   */
  async event void dataReady(uint16_t data);     
}
