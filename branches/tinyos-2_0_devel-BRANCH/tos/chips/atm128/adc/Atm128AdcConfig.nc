/* $Id: Atm128AdcConfig.nc,v 1.1.2.3 2006-01-21 01:31:40 idgay Exp $
 * Copyright (c) 2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
/**
 * Convert ATmega128 HAL A/D interface to the HIL interfaces.
 * @author David Gay
 */
/**
 * Configure ADC channels which need a reference voltage and/or a prescaler
 * different from the default of ATM128_ADC_VREF_OFF and ATM128_ADC_PRESCALE
 */
interface Atm128AdcConfig {
  /**
   * Return the A/D channel to use for this client
   */
  async command uint8_t getChannel();

  /**
   * Return the reference voltage to use for this client
   */
  async command uint8_t getRefVoltage();

  /**
   * Return the prescaler value to use for this client
   */
  async command uint8_t getPrescaler();
}
