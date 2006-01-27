/* $Id: PhotoP.nc,v 1.1.2.2 2006-01-27 19:53:15 idgay Exp $
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
  uses interface GeneralIO as PhotoPin;
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
    return 5;
  }

  async command uint8_t Atm128AdcConfig.getRefVoltage() {
    return ATM128_ADC_VREF_OFF;
  }

  async command uint8_t Atm128AdcConfig.getPrescaler() {
    return ATM128_ADC_PRESCALE;
  }
}
