/**
 * Turn basicsb temp sensor on/off
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
