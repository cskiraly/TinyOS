includes Msp430Adc12;

module Msp430InternalVoltageP {
  provides interface Msp430Adc12Config;
}
implementation {

  async command msp430adc12_channel_config_t Msp430Adc12Config.getChannelSettings() {
    msp430adc12_channel_config_t config = {
      inch: SUPPLY_VOLTAGE_HALF_CHANNEL,
      sref: REFERENCE_VREFplus_AVss,
      ref2_5v: REFVOLT_LEVEL_1_5,
      adc12ssel: SHT_SOURCE_ACLK,
      adc12div: SHT_CLOCK_DIV_1,
      sht: SAMPLE_HOLD_4_CYCLES,
      sampcon_ssel: SAMPCON_SOURCE_SMCLK,
      sampcon_id: SAMPCON_CLOCK_DIV_1
    };

    return config;
  }
}
