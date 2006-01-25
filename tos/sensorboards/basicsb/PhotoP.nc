/**
 * Turn basicsb photo sensor on/off
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
