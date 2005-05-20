/*
 * Copyright (c) 2004, Technische Universitaet Berlin
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
 * - Neither the name of the Technische Universitaet Berlin nor the names
 *   of its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES {} LOSS OF USE, DATA,
 * OR PROFITS {} OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * - Description ---------------------------------------------------------
 * Controlling the TDA5250 at the HPL layer for use with the MSP430 on the 
 * eyesIFX platforms, Configuration.
 * - Revision -------------------------------------------------------------
 * $Revision: 1.1.2.1 $
 * $Date: 2005-05-20 12:55:44 $
 * @author Kevin Klues (klues@tkn.tu-berlin.de)
 * ========================================================================
 */
 
module HPLTDA5250M {
  provides {
    interface Init;
    interface HPLTDA5250Config;
  }
  uses {
    interface HPLTDA5250RegComm;
    interface GeneralIO as TXRX;     
    interface GeneralIO as PWDDD;
    interface Interrupt as PWDDDInterrupt;
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
       
     // reset the radio to default values
     call HPLTDA5250Config.reset();
     
     //Initializing interrupt for use in Timer and SelfPolling modes
     call PWDDDInterrupt.startWait(FALSE);
     
     return SUCCESS;
   }

   /**
    * Reset all Radio Registers to the default values as defined
    * in the tda5250RegDefaults.h file
    */    
   async command void HPLTDA5250Config.reset() {  
     //Keep three state variables to know current value of 
     //config register, ClockDiv, and Lpf register
     currentConfig = TDA5250_DATA_CONFIG_DEFAULT;
     currentClockDiv = TDA5250_DATA_CLK_DIV_DEFAULT; 
     currentLpf = TDA5250_DATA_LPF_DEFAULT;         
     call HPLTDA5250RegComm.writeWord(TDA5250_ADRW_CONFIG, TDA5250_DATA_CONFIG_DEFAULT);
     call HPLTDA5250RegComm.writeWord(TDA5250_ADRW_FSK, TDA5250_DATA_FSK_DEFAULT);
     call HPLTDA5250RegComm.writeWord(TDA5250_ADRW_XTAL_TUNING, TDA5250_DATA_XTAL_TUNING_DEFAULT);
     call HPLTDA5250RegComm.writeByte(TDA5250_ADRW_LPF, TDA5250_DATA_LPF_DEFAULT);
     call HPLTDA5250RegComm.writeWord(TDA5250_ADRW_ON_TIME, TDA5250_DATA_ON_TIME_DEFAULT);
     call HPLTDA5250RegComm.writeWord(TDA5250_ADRW_OFF_TIME, TDA5250_DATA_OFF_TIME_DEFAULT);
     call HPLTDA5250RegComm.writeWord(TDA5250_ADRW_COUNT_TH1, TDA5250_DATA_COUNT_TH1_DEFAULT);
     call HPLTDA5250RegComm.writeWord(TDA5250_ADRW_COUNT_TH2, TDA5250_DATA_COUNT_TH2_DEFAULT);
     call HPLTDA5250RegComm.writeByte(TDA5250_ADRW_RSSI_TH3, TDA5250_DATA_RSSI_TH3_DEFAULT);
     call HPLTDA5250RegComm.writeByte(TDA5250_ADRW_CLK_DIV, TDA5250_DATA_CLK_DIV_DEFAULT);
     call HPLTDA5250RegComm.writeByte(TDA5250_ADRW_XTAL_CONFIG, TDA5250_DATA_XTAL_CONFIG_DEFAULT);
     call HPLTDA5250RegComm.writeWord(TDA5250_ADRW_BLOCK_PD, TDA5250_DATA_BLOCK_PD_DEFAULT);
   }
   
   /**
    * Set the contents of the CONFIG register
    */    
   async command void HPLTDA5250Config.SetRegisterCONFIG(uint16_t value) {
     currentConfig = value;
     call HPLTDA5250RegComm.writeWord(TDA5250_ADRW_CONFIG, value);
   }
   /**
    * Set the contents of the FSK register
    */       
   async command void HPLTDA5250Config.SetRegisterFSK(uint16_t value) {  
     call HPLTDA5250RegComm.writeWord(TDA5250_ADRW_FSK, value);
   }
   /**
    * Set the contents of the XTAL_TUNING register
    */      
   async command void HPLTDA5250Config.SetRegisterXTAL_TUNING(uint16_t value) {  
     call HPLTDA5250RegComm.writeWord(TDA5250_ADRW_XTAL_TUNING, value);
   }
   /**
    * Set the contents of the LPF register
    */      
   async command void HPLTDA5250Config.SetRegisterLPF(uint8_t value) {  
     currentLpf = value;
     call HPLTDA5250RegComm.writeByte(TDA5250_ADRW_LPF, value);
   }
   async command void HPLTDA5250Config.SetRegisterON_TIME(uint16_t value) {  
     call HPLTDA5250RegComm.writeWord(TDA5250_ADRW_ON_TIME, value);   
   }
   /**
    * Set the contents of the OFF_TIME register
    */      
   async command void HPLTDA5250Config.SetRegisterOFF_TIME(uint16_t value) {   
     call HPLTDA5250RegComm.writeWord(TDA5250_ADRW_OFF_TIME, value);
   }
   /**
    * Set the contents of the COUNT_TH1 register
    */      
   async command void HPLTDA5250Config.SetRegisterCOUNT_TH1(uint16_t value) {   
     call HPLTDA5250RegComm.writeWord(TDA5250_ADRW_COUNT_TH1, value);
   }
   /**
    * Set the contents of the COUNT_TH2 register
    */      
   async command void HPLTDA5250Config.SetRegisterCOUNT_TH2(uint16_t value) {
     call HPLTDA5250RegComm.writeWord(TDA5250_ADRW_COUNT_TH2, value); 
   }
   /**
    * Set the contents of the RSSI_TH3 register
    */      
   async command void HPLTDA5250Config.SetRegisterRSSI_TH3(uint8_t value) {   
     call HPLTDA5250RegComm.writeByte(TDA5250_ADRW_RSSI_TH3, value); 
   }
   /**
    * Set the contents of the CLK_DIV register
    */      
   async command void HPLTDA5250Config.SetRegisterCLK_DIV(uint8_t value) {   
     call HPLTDA5250RegComm.writeByte(TDA5250_ADRW_CLK_DIV, value);
     currentClockDiv = value;
   }
   /**
    * Set the contents of the XTAL_CONFIG register
    */      
   async command void HPLTDA5250Config.SetRegisterXTAL_CONFIG(uint8_t value) {   
     call HPLTDA5250RegComm.writeByte(TDA5250_ADRW_XTAL_CONFIG, value);
   }
   /**
    * Set the contents of the BLOCK_PD register
    */      
   async command void HPLTDA5250Config.SetRegisterBLOCK_PD(uint16_t value) {  
     call HPLTDA5250RegComm.writeWord(TDA5250_ADRW_BLOCK_PD, value);  
   }
   
   async command void HPLTDA5250Config.SetLowPassFilter(TDA5250DataCutoffFreqs_t data_cutoff){  
     currentLpf = (((data_cutoff << 4) | (currentLpf & 0x0F)));
     call HPLTDA5250RegComm.writeByte(TDA5250_ADRW_LPF, currentLpf);     
   }
   async command void HPLTDA5250Config.SetIQFilter(TDA5250IqCutoffFreqs_t iq_cutoff){  
     currentLpf = (((iq_cutoff & 0x0F) | (currentLpf & 0xF0)));
     call HPLTDA5250RegComm.writeByte(TDA5250_ADRW_LPF, currentLpf);         
   }
   async command void HPLTDA5250Config.UseRCIntegrator() {
     currentConfig = CONFIG_SLICER_RC_INTEGRATOR(currentConfig);
     call HPLTDA5250RegComm.writeWord(TDA5250_ADRW_CONFIG, currentConfig);     
   }  
   async command void HPLTDA5250Config.UsePeakDetector() {
     currentConfig = CONFIG_SLICER_PEAK_DETECTOR(currentConfig);
     call HPLTDA5250RegComm.writeWord(TDA5250_ADRW_CONFIG, currentConfig);     
   }
   async command void HPLTDA5250Config.PowerDown() {   
     currentConfig = CONFIG_ALL_PD_POWER_DOWN(currentConfig);
     call HPLTDA5250RegComm.writeWord(TDA5250_ADRW_CONFIG, currentConfig);     
   }
   async command void HPLTDA5250Config.PowerUp() { 
     currentConfig = CONFIG_ALL_PD_NORMAL(currentConfig);
     call HPLTDA5250RegComm.writeWord(TDA5250_ADRW_CONFIG, currentConfig);     
   }
   async command void HPLTDA5250Config.RunInTestMode() {
     currentConfig = CONFIG_TESTMODE_TESTMODE(currentConfig);
     call HPLTDA5250RegComm.writeWord(TDA5250_ADRW_CONFIG, currentConfig); 
   }
   async command void HPLTDA5250Config.RunInNormalMode() { 
     currentConfig = CONFIG_TESTMODE_NORMAL(currentConfig);
     call HPLTDA5250RegComm.writeWord(TDA5250_ADRW_CONFIG, currentConfig);    
   }
   async command void HPLTDA5250Config.ControlRxTxExternally() {   
     currentConfig = CONFIG_CONTROL_TXRX_EXTERNAL(currentConfig);
     call HPLTDA5250RegComm.writeWord(TDA5250_ADRW_CONFIG, currentConfig);  
   }
   async command void HPLTDA5250Config.ControlRxTxInternally() {  
     currentConfig = CONFIG_CONTROL_TXRX_REGISTER(currentConfig);
     call HPLTDA5250RegComm.writeWord(TDA5250_ADRW_CONFIG, currentConfig);   
   }
 
   async command void HPLTDA5250Config.UseFSK(TDA5250CapVals_t pos_shift, TDA5250CapVals_t neg_shift) {
     if((currentConfig | MASK_CONFIG_CONTROL_TXRX_REGISTER) == TRUE) {  
       currentConfig = CONFIG_ASK_NFSK_FSK(currentConfig);
       call HPLTDA5250RegComm.writeWord(TDA5250_ADRW_CONFIG, currentConfig);
     }
     //else ***** For Platforms that have a connection to the FSK pin *******
     call HPLTDA5250RegComm.writeWord(TDA5250_ADRW_FSK, ((uint16_t)((((uint16_t)pos_shift) << 8) + neg_shift)));    
   }
   async command void HPLTDA5250Config.UseASK(TDA5250CapVals_t value) {
     if((currentConfig | MASK_CONFIG_CONTROL_TXRX_REGISTER) == TRUE) {  
       currentConfig = CONFIG_ASK_NFSK_ASK(currentConfig);
       call HPLTDA5250RegComm.writeWord(TDA5250_ADRW_CONFIG, currentConfig);
     }
     //else ***** For Platforms that have a connection to the FSK pin *******
     call HPLTDA5250RegComm.writeWord(TDA5250_ADRW_FSK, (((uint16_t)value) << 8));    
   }
   async command void HPLTDA5250Config.SetClockOffDuringPowerDown() {  
     currentConfig = CONFIG_CLK_EN_OFF(currentConfig);
     call HPLTDA5250RegComm.writeWord(TDA5250_ADRW_CONFIG, currentConfig);      
   }
   async command void HPLTDA5250Config.SetClockOnDuringPowerDown() {  
     currentConfig = CONFIG_CLK_EN_ON(currentConfig);
     call HPLTDA5250RegComm.writeWord(TDA5250_ADRW_CONFIG, currentConfig);     
   }
   async command void HPLTDA5250Config.InvertData() {  
     currentConfig = CONFIG_RX_DATA_INV_YES(currentConfig);
     call HPLTDA5250RegComm.writeWord(TDA5250_ADRW_CONFIG, currentConfig);      
   }
   async command void HPLTDA5250Config.DontInvertData() {  
     currentConfig = CONFIG_RX_DATA_INV_NO(currentConfig);
     call HPLTDA5250RegComm.writeWord(TDA5250_ADRW_CONFIG, currentConfig);    
   }
   async command void HPLTDA5250Config.UseRSSIDataValidDetection(uint8_t value, uint16_t lower_bound, uint16_t upper_bound) {  
     currentConfig = CONFIG_D_OUT_IFVALID(currentConfig);
     call HPLTDA5250RegComm.writeWord(TDA5250_ADRW_CONFIG, currentConfig);   
     call HPLTDA5250RegComm.writeWord(TDA5250_ADRW_COUNT_TH1, lower_bound);  
     call HPLTDA5250RegComm.writeWord(TDA5250_ADRW_COUNT_TH2, upper_bound);
     call HPLTDA5250RegComm.writeByte(TDA5250_ADRW_RSSI_TH3, 0xC0 | value);
   }
   
   async command void HPLTDA5250Config.UseVCCDataValidDetection(uint8_t value, uint16_t lower_bound, uint16_t upper_bound) { 
     currentConfig = CONFIG_D_OUT_IFVALID(currentConfig);
     call HPLTDA5250RegComm.writeWord(TDA5250_ADRW_CONFIG, currentConfig);   
     call HPLTDA5250RegComm.writeWord(TDA5250_ADRW_COUNT_TH1, lower_bound);
     call HPLTDA5250RegComm.writeWord(TDA5250_ADRW_COUNT_TH2, upper_bound);
     call HPLTDA5250RegComm.writeByte(TDA5250_ADRW_RSSI_TH3, 0x3F & value);
   }
   
   async command void HPLTDA5250Config.UseDataValidDetection() {  
     currentConfig = CONFIG_D_OUT_IFVALID(currentConfig);
     call HPLTDA5250RegComm.writeWord(TDA5250_ADRW_CONFIG, currentConfig);       
   }
   
   async command void HPLTDA5250Config.UseDataAlwaysValid() { 
     currentConfig = CONFIG_D_OUT_ALWAYS(currentConfig);
     call HPLTDA5250RegComm.writeWord(TDA5250_ADRW_CONFIG, currentConfig);    
   }
   async command void HPLTDA5250Config.ADCContinuousMode() {   
     currentConfig = CONFIG_ADC_MODE_CONT(currentConfig);
     call HPLTDA5250RegComm.writeWord(TDA5250_ADRW_CONFIG, currentConfig);       
   }
   async command void HPLTDA5250Config.ADCOneShotMode() { 
     currentConfig = CONFIG_ADC_MODE_ONESHOT(currentConfig);
     call HPLTDA5250RegComm.writeWord(TDA5250_ADRW_CONFIG, currentConfig);    
   }
   async command void HPLTDA5250Config.DataValidContinuousMode() { 
     currentConfig = CONFIG_F_COUNT_MODE_CONT(currentConfig);
     call HPLTDA5250RegComm.writeWord(TDA5250_ADRW_CONFIG, currentConfig);      
   }
   async command void HPLTDA5250Config.DataValidOneShotMode() {   
     currentConfig = CONFIG_F_COUNT_MODE_ONESHOT(currentConfig);
     call HPLTDA5250RegComm.writeWord(TDA5250_ADRW_CONFIG, currentConfig);    
   }
   async command void HPLTDA5250Config.HighLNAGain() {  
     currentConfig = CONFIG_LNA_GAIN_HIGH(currentConfig);
     call HPLTDA5250RegComm.writeWord(TDA5250_ADRW_CONFIG, currentConfig);    
   }
   async command void HPLTDA5250Config.LowLNAGain() {  
     currentConfig = CONFIG_LNA_GAIN_LOW(currentConfig);
     call HPLTDA5250RegComm.writeWord(TDA5250_ADRW_CONFIG, currentConfig);   
   }
   async command void HPLTDA5250Config.EnableReceiverInTimedModes() {   
     currentConfig = CONFIG_EN_RX_ENABLE(currentConfig);
     call HPLTDA5250RegComm.writeWord(TDA5250_ADRW_CONFIG, currentConfig);     
   }
   async command void HPLTDA5250Config.DisableReceiverInTimedModes() {  
     currentConfig = CONFIG_EN_RX_DISABLE(currentConfig);
     call HPLTDA5250RegComm.writeWord(TDA5250_ADRW_CONFIG, currentConfig);    
   }
   async command void HPLTDA5250Config.UseHighTxPower() {  
     currentConfig = CONFIG_PA_PWR_HIGHTX(currentConfig);
     call HPLTDA5250RegComm.writeWord(TDA5250_ADRW_CONFIG, currentConfig);     
   }
   async command void HPLTDA5250Config.UseLowTxPower() {   
     currentConfig = CONFIG_PA_PWR_LOWTX(currentConfig);
     call HPLTDA5250RegComm.writeWord(TDA5250_ADRW_CONFIG, currentConfig);    
   }   
   
   async command void HPLTDA5250Config.TuneNomFreqWithBipolarFET(TDA5250BipolarFETRampTimes_t ramp_time, TDA5250CapVals_t cap_val) {
     call HPLTDA5250RegComm.writeByte(TDA5250_ADRW_XTAL_CONFIG, ramp_time);
     call HPLTDA5250RegComm.writeWord(TDA5250_ADRW_XTAL_TUNING, ((uint16_t)cap_val) & 0x003F);
   }
   async command void HPLTDA5250Config.TuneNomFreqWithFET(TDA5250CapVals_t cap_val) {   
     call HPLTDA5250RegComm.writeByte(TDA5250_ADRW_XTAL_CONFIG, 0x00);
     call HPLTDA5250RegComm.writeWord(TDA5250_ADRW_XTAL_TUNING, ((uint16_t)cap_val) & 0x003F);        
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
      call HPLTDA5250RegComm.writeWord(TDA5250_ADRW_CONFIG, currentConfig);    
   }   
   async command void HPLTDA5250Config.SetTimerMode(float on_time, float off_time) {      
      call PWDDD.clr();   
      call HPLTDA5250RegComm.writeWord(TDA5250_ADRW_ON_TIME, TDA5250_CONVERT_TIME(on_time));
      call HPLTDA5250RegComm.writeWord(TDA5250_ADRW_OFF_TIME, TDA5250_CONVERT_TIME(off_time));
      currentConfig = CONFIG_MODE_1_SLAVE_OR_TIMER(currentConfig);
      currentConfig = CONFIG_MODE_2_TIMER(currentConfig);
      call HPLTDA5250RegComm.writeWord(TDA5250_ADRW_CONFIG, currentConfig);     
      call TXRX.set();      
      call PWDDD.makeInput(); 
      call PWDDDInterrupt.startWait(FALSE);
   }
   async command void HPLTDA5250Config.ResetTimerMode() {         
      call PWDDD.clr();        
      currentConfig = CONFIG_MODE_1_SLAVE_OR_TIMER(currentConfig);
      currentConfig = CONFIG_MODE_2_TIMER(currentConfig);
      call HPLTDA5250RegComm.writeWord(TDA5250_ADRW_CONFIG, currentConfig);       
      call PWDDD.makeInput();
      call PWDDDInterrupt.startWait(FALSE); 
   }
   async command void HPLTDA5250Config.SetSelfPollingMode(float on_time, float off_time) {   
      call PWDDD.clr();           
      call HPLTDA5250RegComm.writeWord(TDA5250_ADRW_ON_TIME, TDA5250_CONVERT_TIME(on_time));
      call HPLTDA5250RegComm.writeWord(TDA5250_ADRW_OFF_TIME, TDA5250_CONVERT_TIME(off_time));
      currentConfig = CONFIG_MODE_1_SELF_POLLING(currentConfig);
      call HPLTDA5250RegComm.writeWord(TDA5250_ADRW_CONFIG, currentConfig);            
      call TXRX.set();        
      call PWDDD.makeInput(); 
      call PWDDDInterrupt.startWait(FALSE);     
   }
   async command void HPLTDA5250Config.ResetSelfPollingMode() {      
      call PWDDD.clr();          
      currentConfig = CONFIG_MODE_1_SELF_POLLING(currentConfig);
      call HPLTDA5250RegComm.writeWord(TDA5250_ADRW_CONFIG, currentConfig);          
      call TXRX.set();     
      call PWDDD.makeInput();
      call PWDDDInterrupt.startWait(FALSE);
   }
   /**
      Set the on time and off time of the radio
      (Only makes sense when in TIMER or SELF_POLLING Mode)
   */
   async command void HPLTDA5250Config.SetOnTime_ms(float time) {
      call HPLTDA5250RegComm.writeWord(TDA5250_ADRW_ON_TIME, TDA5250_CONVERT_TIME(time));
   }
   async command void HPLTDA5250Config.SetOffTime_ms(float time) {
      call HPLTDA5250RegComm.writeWord(TDA5250_ADRW_OFF_TIME, TDA5250_CONVERT_TIME(time));
   }
   /**
      Set the frequency that the CLK_DIV outputs
      (Available frequencies given in TDA5250ClockFreq_t struct)
   */
   async command void HPLTDA5250Config.UseSetClock() {
      currentClockDiv &= 0x0F;
      call HPLTDA5250RegComm.writeWord(TDA5250_ADRW_CLK_DIV, currentClockDiv);   
   }
   async command void HPLTDA5250Config.Use18MHzClock() {
      currentClockDiv |= 0x10;
      currentClockDiv &= 0x1F;
      call HPLTDA5250RegComm.writeWord(TDA5250_ADRW_CLK_DIV, currentClockDiv); 
   }
   async command void HPLTDA5250Config.Use32KHzClock() {
      currentClockDiv |= 0x20;
      currentClockDiv &= 0x2F;
      call HPLTDA5250RegComm.writeWord(TDA5250_ADRW_CLK_DIV, currentClockDiv);    
   }
   async command void HPLTDA5250Config.UseWindowCountAsClock() {
      currentClockDiv |= 0x30;
      call HPLTDA5250RegComm.writeWord(TDA5250_ADRW_CLK_DIV, currentClockDiv);   
   }
   async command void HPLTDA5250Config.SetRadioClock(TDA5250ClockOutFreqs_t freq) {
      currentClockDiv = (currentClockDiv & 0x30) + freq;
      call HPLTDA5250RegComm.writeWord(TDA5250_ADRW_CLK_DIV, currentClockDiv);  
   }
   
   /**
      Sets the threshold Values for internal evaluation
   */
   async command void HPLTDA5250Config.SetRSSIThreshold(uint8_t value) {   
     call HPLTDA5250RegComm.writeByte(TDA5250_ADRW_RSSI_TH3, 0xC0 | value);
   }
   async command void HPLTDA5250Config.SetVCCOver5Threshold(uint8_t value) { 
     call HPLTDA5250RegComm.writeByte(TDA5250_ADRW_RSSI_TH3, 0x3F & value);      
   }   
   async command void HPLTDA5250Config.SetLowerDataRateThreshold(uint16_t value) {
     call HPLTDA5250RegComm.writeWord(TDA5250_ADRW_COUNT_TH1, value);     
   }
   async command void HPLTDA5250Config.SetUpperDataRateThreshold(uint16_t value) {
     call HPLTDA5250RegComm.writeWord(TDA5250_ADRW_COUNT_TH2, value);     
   }
      
   /**
      Get the exact contents of the readable radio data 
      registers
   */   
   async command uint8_t HPLTDA5250Config.GetRegisterSTATUS() {
     return call HPLTDA5250RegComm.readByte(TDA5250_ADRR_STATUS);
   }
   async command uint8_t HPLTDA5250Config.GetRegisterADC() {
     return call HPLTDA5250RegComm.readByte(TDA5250_ADRR_ADC);
   }
   
   /**
     Get parts of certain registers according to their 
     logical functionality 
   */      
   async command uint8_t HPLTDA5250Config.GetRSSIValue() {
     return (0x3F & call HPLTDA5250RegComm.readByte(TDA5250_ADRR_ADC));
   }
   async command uint8_t HPLTDA5250Config.GetADCSelectFeedbackBit() {
     return ((0x40 & call HPLTDA5250RegComm.readByte(TDA5250_ADRR_ADC)) >> 6);
   }
   async command uint8_t HPLTDA5250Config.GetADCPowerDownFeedbackBit() {
     return ((0x80 & call HPLTDA5250RegComm.readByte(TDA5250_ADRR_ADC)) >> 7);
   }
   async command bool HPLTDA5250Config.IsDataRateLessThanLowerThreshold() {
     if((0x80 & call HPLTDA5250RegComm.readByte(TDA5250_ADRR_STATUS)) == TRUE)
       return TRUE;
     return FALSE;
   }
   async command bool HPLTDA5250Config.IsDataRateBetweenThresholds() {
     if((0x40 & call HPLTDA5250RegComm.readByte(TDA5250_ADRR_STATUS)) == TRUE)
       return TRUE;
     return FALSE;
   }   
   async command bool HPLTDA5250Config.IsDataRateLessThanUpperThreshold() {
     if((0x20 & call HPLTDA5250RegComm.readByte(TDA5250_ADRR_STATUS)) == TRUE)
       return TRUE;
     return FALSE;
   }  
   async command bool HPLTDA5250Config.IsDataRateLessThanHalfOfLowerThreshold() {
     if((0x10 & call HPLTDA5250RegComm.readByte(TDA5250_ADRR_STATUS)) == TRUE)
       return TRUE;
     return FALSE;
   }  
   async command bool HPLTDA5250Config.IsDataRateBetweenHalvesOfThresholds() {
     if((0x08 & call HPLTDA5250RegComm.readByte(TDA5250_ADRR_STATUS)) == TRUE)
       return TRUE;
     return FALSE;
   }  
   async command bool HPLTDA5250Config.IsDataRateLessThanHalfOfUpperThreshold() {
     if((0x04 & call HPLTDA5250RegComm.readByte(TDA5250_ADRR_STATUS)) == TRUE)
       return TRUE;
     return FALSE;
   }  
   async command bool HPLTDA5250Config.IsRSSIEqualToThreshold() {
     if((0x02 & call HPLTDA5250RegComm.readByte(TDA5250_ADRR_STATUS)) == TRUE)
       return TRUE;
     return FALSE;
   }     
   async command bool HPLTDA5250Config.IsRSSIGreaterThanThreshold() {
     if((0x01 & call HPLTDA5250RegComm.readByte(TDA5250_ADRR_STATUS)) == TRUE)
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
       call HPLTDA5250RegComm.writeWord(TDA5250_ADRW_CONFIG, currentConfig);
     }
     else {
       call TXRX.clr();
       call PWDDD.clr();
      }
   }
   
   async command void HPLTDA5250Config.SetRxMode() { 
     if ((currentConfig | MASK_CONFIG_CONTROL_TXRX_REGISTER) == TRUE) {
       currentConfig = CONFIG_RX_NTX_RX(currentConfig);
       currentConfig = CONFIG_ALL_PD_NORMAL(currentConfig);
       call HPLTDA5250RegComm.writeWord(TDA5250_ADRW_CONFIG, currentConfig);
     }
     else {
       call TXRX.set();
       call PWDDD.clr();
     }
   }
   
   async command void HPLTDA5250Config.SetSleepMode() {
     if ((currentConfig | MASK_CONFIG_CONTROL_TXRX_REGISTER) == TRUE) {
       currentConfig = CONFIG_ALL_PD_POWER_DOWN(currentConfig);
       call HPLTDA5250RegComm.writeWord(TDA5250_ADRW_CONFIG, currentConfig);
     }
     else call PWDDD.set();
   }
         
   /****************************************************************
                          Events Implemented
   *****************************************************************/
   /**
      Interrupt Signal on PWD_DD pin in 
      TIMER_MODE and SELF_POLLING_MODE
   */      
   async event void PWDDDInterrupt.fired() {
     signal HPLTDA5250Config.PWDDDInterrupt();
   }

   default async event void HPLTDA5250Config.PWDDDInterrupt() {}
}
