/*
* Copyright (c) 2004, Technische Universitat Berlin
* All rights reserved.
*
* Redistribution and use in source and binary forms, with or without
* modification, are permitted provided that the following conditions
* are met:
* - Redistributions of source code must retain the above copyright notice,
*   this list of conditions and the following disclaimer.
* - Redistributions in binary form must reproduce the above copyright
*   notice, this list of conditions and the following disclaimer in the
*   documentation and/or other materials provided with the distribution.
* - Neither the name of the Technische Universitat Berlin nor the names
*   of its contributors may be used to endorse or promote products derived
*   from this software without specific prior written permission.
*
* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
* "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
* LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
* A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
* OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
* SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
* TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA,
* OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
* OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
* (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
* USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
* - Revision -------------------------------------------------------------
* $Revision: 1.1.2.2 $
* $Date: 2006-01-23 00:54:44 $
* ========================================================================
*/

/**
* HPLTDA5250ConfigM module
*
* @author Kevin Klues (klues@tkn.tu-berlin.de)
*/

module HPLTDA5250ConfigP {
  provides {
    interface Init;
    interface HPLTDA5250Config;
  }
  uses {
    interface TDA5250WriteReg<TDA5250_REG_TYPE_CONFIG>      as CONFIG;
    interface TDA5250WriteReg<TDA5250_REG_TYPE_FSK>         as FSK;
    interface TDA5250WriteReg<TDA5250_REG_TYPE_XTAL_TUNING> as XTAL_TUNING;
    interface TDA5250WriteReg<TDA5250_REG_TYPE_LPF>         as LPF;
    interface TDA5250WriteReg<TDA5250_REG_TYPE_ON_TIME>     as ON_TIME;
    interface TDA5250WriteReg<TDA5250_REG_TYPE_OFF_TIME>    as OFF_TIME;
    interface TDA5250WriteReg<TDA5250_REG_TYPE_COUNT_TH1>   as COUNT_TH1;
    interface TDA5250WriteReg<TDA5250_REG_TYPE_COUNT_TH2>   as COUNT_TH2;
    interface TDA5250WriteReg<TDA5250_REG_TYPE_RSSI_TH3>    as RSSI_TH3;
    interface TDA5250WriteReg<TDA5250_REG_TYPE_RF_POWER>    as RF_POWER;
    interface TDA5250WriteReg<TDA5250_REG_TYPE_CLK_DIV>     as CLK_DIV;
    interface TDA5250WriteReg<TDA5250_REG_TYPE_XTAL_CONFIG> as XTAL_CONFIG;
    interface TDA5250WriteReg<TDA5250_REG_TYPE_BLOCK_PD>    as BLOCK_PD;
    interface TDA5250ReadReg<TDA5250_REG_TYPE_STATUS>       as STATUS;
    interface TDA5250ReadReg<TDA5250_REG_TYPE_ADC>          as ADC;
    interface Alarm<T32khz, uint16_t> as TransmitterDelay;
    interface Alarm<T32khz, uint16_t> as ReceiverDelay;
    interface Alarm<T32khz, uint16_t> as RSSIStableDelay;
    interface GeneralIO as TXRX;
    interface GeneralIO as PWDDD;
    //interface Interrupt as PWDDDInterrupt;
    interface GpioInterrupt as PWDDDInterrupt;
  }
}

implementation {
  /****************************************************************
  Global Variables Declared
  *****************************************************************/
  norace uint16_t currentConfig;
  uint8_t currentClockDiv;
  norace uint8_t currentLpf;

  /****************************************************************
  async commands Implemented
  *****************************************************************/
  /**
  * Initializes the Radio, setting up all Pin configurations
  * to the MicroProcessor that is driving it and resetting
  * all Registers to their default values
  *
  * @return always returns SUCCESS
  */
  command error_t Init.init() {
    // setting pins to output
        call TXRX.makeOutput();
    call PWDDD.makeOutput();

    // initializing pin values
        call TXRX.set();
    call PWDDD.clr();
    return SUCCESS;
  }

  /**
  * Reset all Radio Registers to the default values as defined
  * in the tda5250RegDefaults.h file
  */
  async command void HPLTDA5250Config.reset() {
    //Keep three state variables to know current value of
    //config register, ClockDiv, and Lpf register
        atomic {
          currentConfig = TDA5250_REG_DEFAULT_SETTING_CONFIG;
          currentClockDiv = TDA5250_REG_DEFAULT_SETTING_CLK_DIV;
          currentLpf = TDA5250_REG_DEFAULT_SETTING_LPF;
        }
        call CONFIG.set(TDA5250_REG_DEFAULT_SETTING_CONFIG);
        call FSK.set(TDA5250_REG_DEFAULT_SETTING_FSK);
        call XTAL_TUNING.set(TDA5250_REG_DEFAULT_SETTING_XTAL_TUNING);
        call LPF.set(TDA5250_REG_DEFAULT_SETTING_LPF);
        call ON_TIME.set(TDA5250_REG_DEFAULT_SETTING_ON_TIME);
        call OFF_TIME.set(TDA5250_REG_DEFAULT_SETTING_OFF_TIME);
        call COUNT_TH1.set(TDA5250_REG_DEFAULT_SETTING_COUNT_TH1);
        call COUNT_TH2.set(TDA5250_REG_DEFAULT_SETTING_COUNT_TH2);
        call RSSI_TH3.set(TDA5250_REG_DEFAULT_SETTING_RSSI_TH3);
        call CLK_DIV.set(TDA5250_REG_DEFAULT_SETTING_CLK_DIV);
        call XTAL_CONFIG.set(TDA5250_REG_DEFAULT_SETTING_XTAL_CONFIG);
        call BLOCK_PD.set(TDA5250_REG_DEFAULT_SETTING_BLOCK_PD);
  }

  async command void HPLTDA5250Config.SetLowPassFilter(TDA5250DataCutoffFreqs_t data_cutoff){
    currentLpf = (((data_cutoff << 4) | (currentLpf & 0x0F)));
    call LPF.set(currentLpf);
  }
  async command void HPLTDA5250Config.SetIQFilter(TDA5250IqCutoffFreqs_t iq_cutoff){
    currentLpf = (((iq_cutoff & 0x0F) | (currentLpf & 0xF0)));
    call LPF.set(currentLpf);
  }
  async command void HPLTDA5250Config.UseRCIntegrator() {
    currentConfig = CONFIG_SLICER_RC_INTEGRATOR(currentConfig);
    call CONFIG.set(currentConfig);
  }
  async command void HPLTDA5250Config.UsePeakDetector() {
    currentConfig = CONFIG_SLICER_PEAK_DETECTOR(currentConfig);
    call CONFIG.set(currentConfig);
  }
  async command void HPLTDA5250Config.PowerDown() {
    currentConfig = CONFIG_ALL_PD_POWER_DOWN(currentConfig);
    call CONFIG.set(currentConfig);
  }
  async command void HPLTDA5250Config.PowerUp() {
    currentConfig = CONFIG_ALL_PD_NORMAL(currentConfig);
    call CONFIG.set(currentConfig);
  }
  async command void HPLTDA5250Config.RunInTestMode() {
    currentConfig = CONFIG_TESTMODE_TESTMODE(currentConfig);
    call CONFIG.set(currentConfig);
  }
  async command void HPLTDA5250Config.RunInNormalMode() {
    currentConfig = CONFIG_TESTMODE_NORMAL(currentConfig);
    call CONFIG.set(currentConfig);
  }
  async command void HPLTDA5250Config.ControlRxTxExternally() {
    currentConfig = CONFIG_CONTROL_TXRX_EXTERNAL(currentConfig);
    call CONFIG.set(currentConfig);
  }
  async command void HPLTDA5250Config.ControlRxTxInternally() {
    currentConfig = CONFIG_CONTROL_TXRX_REGISTER(currentConfig);
    call CONFIG.set(currentConfig);
  }

  async command void HPLTDA5250Config.UseFSK(TDA5250CapVals_t pos_shift, TDA5250CapVals_t neg_shift) {
    if((currentConfig | MASK_CONFIG_CONTROL_TXRX_REGISTER) == TRUE) {
      currentConfig = CONFIG_ASK_NFSK_FSK(currentConfig);
      call CONFIG.set(currentConfig);
    }
    //else ***** For Platforms that have a connection to the FSK pin *******
        call FSK.set(((uint16_t)((((uint16_t)pos_shift) << 8) + neg_shift)));
  }
  async command void HPLTDA5250Config.UseASK(TDA5250CapVals_t value) {
    if((currentConfig | MASK_CONFIG_CONTROL_TXRX_REGISTER) == TRUE) {
      currentConfig = CONFIG_ASK_NFSK_ASK(currentConfig);
      call CONFIG.set(currentConfig);
    }
    //else ***** For Platforms that have a connection to the FSK pin *******
        call FSK.set((((uint16_t)value) << 8));
  }
  async command void HPLTDA5250Config.SetClockOffDuringPowerDown() {
    currentConfig = CONFIG_CLK_EN_OFF(currentConfig);
    call CONFIG.set(currentConfig);
  }
  async command void HPLTDA5250Config.SetClockOnDuringPowerDown() {
    currentConfig = CONFIG_CLK_EN_ON(currentConfig);
    call CONFIG.set(currentConfig);
  }
  async command void HPLTDA5250Config.InvertData() {
    currentConfig = CONFIG_RX_DATA_INV_YES(currentConfig);
    call CONFIG.set(currentConfig);
  }
  async command void HPLTDA5250Config.DontInvertData() {
    currentConfig = CONFIG_RX_DATA_INV_NO(currentConfig);
    call CONFIG.set(currentConfig);
  }
  async command void HPLTDA5250Config.UseRSSIDataValidDetection(uint8_t value, uint16_t lower_bound, uint16_t upper_bound) {
    currentConfig = CONFIG_D_OUT_IFVALID(currentConfig);
    call CONFIG.set(currentConfig);
    call COUNT_TH1.set(lower_bound);
    call COUNT_TH2.set(upper_bound);
    call RSSI_TH3.set(0xC0 | value);
  }

  async command void HPLTDA5250Config.UseVCCDataValidDetection(uint8_t value, uint16_t lower_bound, uint16_t upper_bound) {
    currentConfig = CONFIG_D_OUT_IFVALID(currentConfig);
    call CONFIG.set(currentConfig);
    call COUNT_TH1.set(lower_bound);
    call COUNT_TH2.set(upper_bound);
    call RSSI_TH3.set(0x3F & value);
  }

  async command void HPLTDA5250Config.UseDataValidDetection() {
    currentConfig = CONFIG_D_OUT_IFVALID(currentConfig);
    call CONFIG.set(currentConfig);
  }

  async command void HPLTDA5250Config.UseDataAlwaysValid() {
    currentConfig = CONFIG_D_OUT_ALWAYS(currentConfig);
    call CONFIG.set(currentConfig);
  }
  async command void HPLTDA5250Config.ADCContinuousMode() {
    currentConfig = CONFIG_ADC_MODE_CONT(currentConfig);
    call CONFIG.set(currentConfig);
  }
  async command void HPLTDA5250Config.ADCOneShotMode() {
    currentConfig = CONFIG_ADC_MODE_ONESHOT(currentConfig);
    call CONFIG.set(currentConfig);
  }
  async command void HPLTDA5250Config.DataValidContinuousMode() {
    currentConfig = CONFIG_F_COUNT_MODE_CONT(currentConfig);
    call CONFIG.set(currentConfig);
  }
  async command void HPLTDA5250Config.DataValidOneShotMode() {
    currentConfig = CONFIG_F_COUNT_MODE_ONESHOT(currentConfig);
    call CONFIG.set(currentConfig);
  }
  async command void HPLTDA5250Config.HighLNAGain() {
    currentConfig = CONFIG_LNA_GAIN_HIGH(currentConfig);
    call CONFIG.set(currentConfig);
  }
  async command void HPLTDA5250Config.LowLNAGain() {
    currentConfig = CONFIG_LNA_GAIN_LOW(currentConfig);
    call CONFIG.set(currentConfig);
  }
  async command void HPLTDA5250Config.EnableReceiverInTimedModes() {
    currentConfig = CONFIG_EN_RX_ENABLE(currentConfig);
    call CONFIG.set(currentConfig);
  }
  async command void HPLTDA5250Config.DisableReceiverInTimedModes() {
    currentConfig = CONFIG_EN_RX_DISABLE(currentConfig);
    call CONFIG.set(currentConfig);
  }
  async command void HPLTDA5250Config.UseHighTxPower() {
    currentConfig = CONFIG_PA_PWR_HIGHTX(currentConfig);
    call CONFIG.set(currentConfig);
  }
  async command void HPLTDA5250Config.UseLowTxPower() {
    currentConfig = CONFIG_PA_PWR_LOWTX(currentConfig);
    call CONFIG.set(currentConfig);
  }

  async command void HPLTDA5250Config.TuneNomFreqWithBipolarFET(TDA5250BipolarFETRampTimes_t ramp_time, TDA5250CapVals_t cap_val) {
    call XTAL_CONFIG.set(ramp_time);
    call XTAL_CONFIG.set(((uint16_t)cap_val) & 0x003F);
  }
  async command void HPLTDA5250Config.TuneNomFreqWithFET(TDA5250CapVals_t cap_val) {
    call XTAL_CONFIG.set(0x00);
    call XTAL_CONFIG.set(((uint16_t)cap_val) & 0x003F);
  }

  command void HPLTDA5250Config.SetRFPower(uint8_t value) {
    call RF_POWER.set(value);
  }

  /**
  Set the mode of the radio
  The choices are SLAVE_MODE, TIMER_MODE, SELF_POLLING_MODE
  */
  async command void HPLTDA5250Config.SetSlaveMode() {
    call PWDDDInterrupt.disable();
    call PWDDD.makeOutput();
    call PWDDD.clr();
    currentConfig = CONFIG_MODE_1_SLAVE_OR_TIMER(currentConfig);
    currentConfig = CONFIG_MODE_2_SLAVE(currentConfig);
    call CONFIG.set(currentConfig);
  }
  async command void HPLTDA5250Config.SetTimerMode(float on_time, float off_time) {
    call PWDDD.clr();
    call ON_TIME.set(TDA5250_CONVERT_TIME(on_time));
    call OFF_TIME.set(TDA5250_CONVERT_TIME(off_time));
    currentConfig = CONFIG_MODE_1_SLAVE_OR_TIMER(currentConfig);
    currentConfig = CONFIG_MODE_2_TIMER(currentConfig);
    call CONFIG.set(currentConfig);
    call TXRX.set();
    call PWDDD.makeInput();
    // call PWDDDInterrupt.startWait(FALSE);
    call PWDDDInterrupt.enableFallingEdge();
  }
  async command void HPLTDA5250Config.ResetTimerMode() {
    call PWDDD.clr();
    currentConfig = CONFIG_MODE_1_SLAVE_OR_TIMER(currentConfig);
    currentConfig = CONFIG_MODE_2_TIMER(currentConfig);
    call CONFIG.set(currentConfig);
    call PWDDD.makeInput();
    // call PWDDDInterrupt.startWait(FALSE);
    call PWDDDInterrupt.enableFallingEdge();
  }
  async command void HPLTDA5250Config.SetSelfPollingMode(float on_time, float off_time) {
    call PWDDD.clr();
    call ON_TIME.set(TDA5250_CONVERT_TIME(on_time));
    call OFF_TIME.set(TDA5250_CONVERT_TIME(off_time));
    currentConfig = CONFIG_MODE_1_SELF_POLLING(currentConfig);
    call CONFIG.set(currentConfig);
    call TXRX.set();
    call PWDDD.makeInput();
    // call PWDDDInterrupt.startWait(FALSE);
    call PWDDDInterrupt.enableFallingEdge();
  }
  async command void HPLTDA5250Config.ResetSelfPollingMode() {
    call PWDDD.clr();
    currentConfig = CONFIG_MODE_1_SELF_POLLING(currentConfig);
    call CONFIG.set(currentConfig);
    call TXRX.set();
    call PWDDD.makeInput();
    // call PWDDDInterrupt.startWait(FALSE);
    call PWDDDInterrupt.enableFallingEdge();
  }
  /**
  Set the on time and off time of the radio
  (Only makes sense when in TIMER or SELF_POLLING Mode)
  */
  async command void HPLTDA5250Config.SetOnTime_ms(float time) {
    call ON_TIME.set(TDA5250_CONVERT_TIME(time));
  }
  async command void HPLTDA5250Config.SetOffTime_ms(float time) {
    call OFF_TIME.set(TDA5250_CONVERT_TIME(time));
  }
  /**
  Set the frequency that the CLK_DIV outputs
  (Available frequencies given in TDA5250ClockFreq_t struct)
  */
  async command void HPLTDA5250Config.UseSetClock() {
    currentClockDiv &= 0x0F;
    call CLK_DIV.set(currentClockDiv);
  }
  async command void HPLTDA5250Config.Use18MHzClock() {
    currentClockDiv |= 0x10;
    currentClockDiv &= 0x1F;
    call CLK_DIV.set(currentClockDiv);
  }
  async command void HPLTDA5250Config.Use32KHzClock() {
    currentClockDiv |= 0x20;
    currentClockDiv &= 0x2F;
    call CLK_DIV.set(currentClockDiv);
  }
  async command void HPLTDA5250Config.UseWindowCountAsClock() {
    currentClockDiv |= 0x30;
    call CLK_DIV.set(currentClockDiv);
  }
  async command void HPLTDA5250Config.SetRadioClock(TDA5250ClockOutFreqs_t freq) {
    currentClockDiv = (currentClockDiv & 0x30) + freq;
    call CLK_DIV.set(currentClockDiv);
  }

  /**
  Sets the threshold Values for internal evaluation
  */
  async command void HPLTDA5250Config.SetRSSIThreshold(uint8_t value) {
    call RSSI_TH3.set(0xC0 | value);
  }
  async command void HPLTDA5250Config.SetVCCOver5Threshold(uint8_t value) {
    call RSSI_TH3.set(0x3F & value);
  }
  async command void HPLTDA5250Config.SetLowerDataRateThreshold(uint16_t value) {
    call COUNT_TH1.set(value);
  }
  async command void HPLTDA5250Config.SetUpperDataRateThreshold(uint16_t value) {
    call COUNT_TH2.set(value);
  }

  /**
  Get parts of certain registers according to their
  logical functionality
  */
  async command uint8_t HPLTDA5250Config.GetRSSIValue() {
    return (0x3F & call ADC.get());
  }
  async command uint8_t HPLTDA5250Config.GetADCSelectFeedbackBit() {
    return ((0x40 & call ADC.get()) >> 6);
  }
  async command uint8_t HPLTDA5250Config.GetADCPowerDownFeedbackBit() {
    return ((0x80 & call ADC.get()) >> 7);
  }
  async command bool HPLTDA5250Config.IsDataRateLessThanLowerThreshold() {
    if((0x80 & call STATUS.get()) == TRUE)
      return TRUE;
    return FALSE;
  }
  async command bool HPLTDA5250Config.IsDataRateBetweenThresholds() {
    if((0x40 & call STATUS.get()) == TRUE)
      return TRUE;
    return FALSE;
  }
  async command bool HPLTDA5250Config.IsDataRateLessThanUpperThreshold() {
    if((0x20 & call STATUS.get()) == TRUE)
      return TRUE;
    return FALSE;
  }
  async command bool HPLTDA5250Config.IsDataRateLessThanHalfOfLowerThreshold() {
    if((0x10 & call STATUS.get()) == TRUE)
      return TRUE;
    return FALSE;
  }
  async command bool HPLTDA5250Config.IsDataRateBetweenHalvesOfThresholds() {
    if((0x08 & call STATUS.get()) == TRUE)
      return TRUE;
    return FALSE;
  }
  async command bool HPLTDA5250Config.IsDataRateLessThanHalfOfUpperThreshold() {
    if((0x04 & call STATUS.get()) == TRUE)
      return TRUE;
    return FALSE;
  }
  async command bool HPLTDA5250Config.IsRSSIEqualToThreshold() {
    if((0x02 & call STATUS.get()) == TRUE)
      return TRUE;
    return FALSE;
  }
  async command bool HPLTDA5250Config.IsRSSIGreaterThanThreshold() {
    if((0x01 & call STATUS.get()) == TRUE)
      return TRUE;
    return FALSE;
  }

  /**
  Switches radio between states when in SLAVE_MODE
  */
  async command void HPLTDA5250Config.SetTxMode() {
    if ((currentConfig | MASK_CONFIG_CONTROL_TXRX_REGISTER) == TRUE) {
      currentConfig = CONFIG_RX_NTX_TX(currentConfig);
      currentConfig = CONFIG_ALL_PD_NORMAL(currentConfig);
      call CONFIG.set(currentConfig);
    }
    else {
      call TXRX.clr();
      call PWDDD.clr();
    }
                        // call TransmitterDelay.startNow(TDA5250_TRANSMITTER_SETUP_TIME);
                        call TransmitterDelay.start(TDA5250_TRANSMITTER_SETUP_TIME);
  }

  async command void HPLTDA5250Config.SetRxMode() {
    if ((currentConfig | MASK_CONFIG_CONTROL_TXRX_REGISTER) == TRUE) {
      currentConfig = CONFIG_RX_NTX_RX(currentConfig);
      currentConfig = CONFIG_ALL_PD_NORMAL(currentConfig);
      call CONFIG.set(currentConfig);
    }
    else {
      call TXRX.set();
      call PWDDD.clr();
    }
                // call ReceiverDelay.startNow(TDA5250_RECEIVER_SETUP_TIME);
                call ReceiverDelay.start(TDA5250_RECEIVER_SETUP_TIME);
  }

  async command void HPLTDA5250Config.SetSleepMode() {
    if ((currentConfig | MASK_CONFIG_CONTROL_TXRX_REGISTER) == TRUE) {
      currentConfig = CONFIG_ALL_PD_POWER_DOWN(currentConfig);
      call CONFIG.set(currentConfig);
    }
    else {
      call PWDDD.makeOutput();
      call PWDDD.set();
    }
    signal HPLTDA5250Config.SetSleepModeDone();
  }

  /****************************************************************
  Events Implemented
  ************************************************/
  /**
  Interrupt Signal on PWD_DD pin in
  TIMER_MODE and SELF_POLLING_MODE
  */
  async event void PWDDDInterrupt.fired() {
    signal HPLTDA5250Config.PWDDDInterrupt();
  }

  async event void TransmitterDelay.fired() {
    signal HPLTDA5250Config.SetTxModeDone();
  }

  async event void ReceiverDelay.fired() {
          // call RSSIStableDelay.startNow(TDA5250_RSSI_STABLE_TIME-TDA5250_RECEIVER_SETUP_TIME);
          call RSSIStableDelay.start(TDA5250_RSSI_STABLE_TIME-TDA5250_RECEIVER_SETUP_TIME);
          signal HPLTDA5250Config.SetRxModeDone();
  }

  async event void RSSIStableDelay.fired() {
    signal HPLTDA5250Config.RSSIStable();
  }

  default async event void HPLTDA5250Config.PWDDDInterrupt() {}
}
