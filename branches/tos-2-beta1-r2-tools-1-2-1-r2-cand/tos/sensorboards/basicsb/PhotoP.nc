/* $Id: PhotoP.nc,v 1.1.2.4 2006-02-02 01:03:29 idgay Exp $
 * Copyright (c) 2006 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
/**
 * basicsb photodiode power control and ADC configuration.
 * @author David Gay <david.e.gay@intel.com>
 */
module PhotoP
{
  provides {
    interface StdControl;
    interface Atm128AdcConfig;
  }
  uses {
    interface GeneralIO as PhotoPin;
    interface MicaBusAdc as PhotoAdc;
  }
}
implementation
{
  command error_t StdControl.start() {
    call PhotoPin.makeOutput();
    call PhotoPin.set();
    return SUCCESS;
  }

  command error_t StdControl.stop() {
    call PhotoPin.clr();
    return SUCCESS;
  }

  async command uint8_t Atm128AdcConfig.getChannel() {
    return call PhotoAdc.getChannel();
  }

  async command uint8_t Atm128AdcConfig.getRefVoltage() {
    return ATM128_ADC_VREF_OFF;
  }

  async command uint8_t Atm128AdcConfig.getPrescaler() {
    return ATM128_ADC_PRESCALE;
  }
}
