/* $Id: TempP.nc,v 1.1.2.2 2006-01-27 19:53:15 idgay Exp $
 * Copyright (c) 2006 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
/**
 * basicsb thermistor power control and ADC configuration.
 * @author David Gay <david.e.gay@intel.com>
 */
module TempP
{
  provides {
    interface StdControl;
    interface Atm128AdcConfig;
  }
  uses interface GeneralIO as TempPin;
}
implementation
{
  command error_t StdControl.start() {
    call TempPin.makeOutput();
    call TempPin.set();
    return SUCCESS;
  }

  command error_t StdControl.stop() {
    call TempPin.clr();
    return SUCCESS;
  }

  async command uint8_t Atm128AdcConfig.getChannel() {
    return 6;
  }

  async command uint8_t Atm128AdcConfig.getRefVoltage() {
    return ATM128_ADC_VREF_OFF;
  }

  async command uint8_t Atm128AdcConfig.getPrescaler() {
    return ATM128_ADC_PRESCALE;
  }
}
