/*									tab:4
 *  IMPORTANT: READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.  By
 *  downloading, copying, installing or using the software you agree to
 *  this license.  If you do not agree to this license, do not download,
 *  install, copy or use the software.
 *
 *  Intel Open Source License 
 *
 *  Copyright (c) 2002 Intel Corporation 
 *  All rights reserved. 
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions are
 *  met:
 * 
 *	Redistributions of source code must retain the above copyright
 *  notice, this list of conditions and the following disclaimer.
 *	Redistributions in binary form must reproduce the above copyright
 *  notice, this list of conditions and the following disclaimer in the
 *  documentation and/or other materials provided with the distribution.
 *      Neither the name of the Intel Corporation nor the names of its
 *  contributors may be used to endorse or promote products derived from
 *  this software without specific prior written permission.
 *  
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 *  ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 *  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 *  PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE INTEL OR ITS
 *  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 *  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 *  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 *  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 *  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 *  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 *  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * 
 */

/*
 *
 * Authors:  Lama Nachman, Robert Adler
 */

#define START_RADIO_LDO 1
#define START_SENSOR_BOARD_LDO 1
/*
 * VCC_MEM is connected to BUCK2 by default, make sure you have a board
 * that has the right resistor settings before disabling BUCK2
 */
#define DISABLE_BUCK2 0	

//includes trace;

module PMICM{
  provides{
    interface Init;
    //interface BluSH_AppI as BatteryVoltage; 
    //interface BluSH_AppI as AutoCharging;
    //interface BluSH_AppI as ManualCharging;
    //interface BluSH_AppI as ChargingStatus;
    //interface PMIC;
  }

}

implementation {
#include "pmic.h"
  
  bool gotReset;
  
  
  error_t readPMIC(uint8_t address, uint8_t *value, uint8_t numBytes){
    //send the PMIC the address that we want to read
    if(numBytes > 0){
      PIDBR = PMIC_SLAVE_ADDR<<1; 
      PICR |= ICR_START;
      PICR |= ICR_TB;
      while(PICR & ICR_TB);
      
      //actually send the address terminated with a STOP
      PIDBR = address;
      PICR &= ~ICR_START;
      PICR |= ICR_STOP;
      PICR |= ICR_TB;
      while(PICR & ICR_TB);
      PICR &= ~ICR_STOP;
      
      
      //actually request the read of the data
      PIDBR = PMIC_SLAVE_ADDR<<1 | 1; 
      PICR |= ICR_START;
      PICR |= ICR_TB;
      while(PICR & ICR_TB);
      PICR &= ~ICR_START;
      
      //using Page Read Mode
      while (numBytes > 1){
	PICR |= ICR_TB;
	while(PICR & ICR_TB);
	*value = PIDBR;
	value++;
	numBytes--;
      }
      
      PICR |= ICR_STOP;
      PICR |= ICR_ACKNAK;
      PICR |= ICR_TB;
      while(PICR & ICR_TB);
      *value = PIDBR;
      PICR &= ~ICR_STOP;
      PICR &= ~ICR_ACKNAK;
      
      return SUCCESS;
    }
    else{
      return FAIL;
    }
  }

  error_t writePMIC(uint8_t address, uint8_t value){
    PIDBR = PMIC_SLAVE_ADDR<<1;
    PICR |= ICR_START;
    PICR |= ICR_TB;
    while(PICR & ICR_TB);
    
    PIDBR = address;
    PICR &= ~ICR_START;
    PICR |= ICR_TB;
    while(PICR & ICR_TB);

    PIDBR = value;
    PICR |= ICR_STOP;
    PICR |= ICR_TB;
    while(PICR & ICR_TB);
    PICR &= ~ICR_STOP;

    return SUCCESS;
  }
  
  void startLDOs() {
    uint8_t temp;
    uint8_t oldVal, newVal;

#if START_SENSOR_BOARD_LDO 
    // TODO : Need to move out of here to sensor board functions
    readPMIC(PMIC_A_REG_CONTROL_1, &oldVal, 1);
    newVal = oldVal | ARC1_LDO10_EN | ARC1_LDO11_EN;	// sensor board
    writePMIC(PMIC_A_REG_CONTROL_1, newVal);

    readPMIC(PMIC_B_REG_CONTROL_2, &oldVal, 1);
    newVal = oldVal | BRC2_LDO10_EN | BRC2_LDO11_EN;
    writePMIC(PMIC_B_REG_CONTROL_2, newVal);
#endif

#if START_RADIO_LDO
    // TODO : Move to radio start
    readPMIC(PMIC_B_REG_CONTROL_1, &oldVal, 1);
    newVal = oldVal | BRC1_LDO5_EN; 
    writePMIC(PMIC_B_REG_CONTROL_1, newVal);
#endif

#if DISABLE_BUCK2  // Disable BUCK2 if VCC_MEM is not configured to use BUCK2
    readPMIC(PMIC_B_REG_CONTROL_1, &oldVal, 1);
    newVal = oldVal & ~BRC1_BUCK_EN;
    writePMIC(PMIC_B_REG_CONTROL_1, newVal);
#endif

#if 0
    // Configure above LDOs, Radio and sensor board LDOs to turn off in sleep
    // TODO : Sleep setting doesn't work
    temp = BSC1_LDO1(1) | BSC1_LDO2(1) | BSC1_LDO3(1) | BSC1_LDO4(1);
    writePMIC(PMIC_B_SLEEP_CONTROL_1, temp);
    temp = BSC2_LDO5(1) | BSC2_LDO7(1) | BSC2_LDO8(1) | BSC2_LDO9(1);
    writePMIC(PMIC_B_SLEEP_CONTROL_2, temp);
    temp = BSC3_LDO12(1); 
    writePMIC(PMIC_B_SLEEP_CONTROL_3, temp);
#endif
  }

  error_t startPMICstuff() {
    //command result_t StdControl.start(){ XXX-pb
    //init unit
    uint8_t val[3];
    //call PI2CInterrupt.enable(); XXX-pb
    //irq is apparently active low...however trigger on both for now
    //call PMICInterrupt.enable(TOSH_FALLING_EDGE); XXX-pb
        
    /*
     * Reset the watchdog, switch it to an interrupt, so we can disable it
     * Ignore SLEEP_N pin, enable H/W reset via button 
     */
    writePMIC(PMIC_SYS_CONTROL_A, 
              SCA_RESET_WDOG | SCA_WDOG_ACTION | SCA_HWRES_EN);

    // Disable all interrupts from PMIC except for ONKEY button
    writePMIC(PMIC_IRQ_MASK_A, ~IMA_ONKEY_N);
    writePMIC(PMIC_IRQ_MASK_B, 0xFF);
    writePMIC(PMIC_IRQ_MASK_C, 0xFF);
    
    //read out the EVENT registers so that we can receive interrupts
    readPMIC(PMIC_EVENTS, val, 3);

#ifdef PXA27X_13M
    // Set default core voltage to 0.85 V
    //call PMIC.setCoreVoltage(B2R1_TRIM_P85_V); 
    writePMIC(PMIC_BUCK2_REG1, (B2R1_TRIM_P95_V & B2R1_TRIM_MASK) | B2R1_GO);
#else
    writePMIC(PMIC_BUCK2_REG1, (B2R1_TRIM_1_25_V & B2R1_TRIM_MASK) | B2R1_GO);
#endif

    startLDOs();
    return SUCCESS;
  }
  command error_t Init.init(){
    CKEN |= CKEN15_PMI2C;
    PCFR |= PCFR_PI2C_EN;
    PICR = ICR_IUE | ICR_SCLE;
    atomic{
      gotReset=FALSE;
    }    
    //return call PI2CInterrupt.allocate(); XXX-pb
    return startPMICstuff();
  }

#if 0  
  command result_t StdControl.stop(){
    call PI2CInterrupt.disable();
    call PMICInterrupt.disable();
    CKEN &= ~CKEN15_PMI2C;
    PICR = 0;
    
    return SUCCESS;
  }
  
  async event void PI2CInterrupt.fired(){
    uint32_t status, update=0;
    status = PISR;
    if(status & ISR_ITE){
      update |= ISR_ITE;
      trace(DBG_USR1,"sent data");
    }

    if(status & ISR_BED){
      update |= ISR_BED;
      trace(DBG_USR1,"bus error");
    }
    PISR = update;
  }
  
  async event void PMICInterrupt.fired(){
    uint8_t events[3];
    bool localGotReset;
   
    call PMICInterrupt.clear();
   
    readPMIC(PMIC_EVENTS, events, 3);
   
    if(events[EVENTS_A_OFFSET] & EA_ONKEY_N){
      atomic{
        localGotReset = gotReset;
      }
      if(localGotReset==TRUE){
        call Reset.reset();
      }
      else{
        atomic{
	  gotReset=TRUE;
        }
      }
    }
    else{
      trace(DBG_USR1,"PMIC EVENTs =%#x %#x %#x\r\n",events[0], events[1], events[2]);
    }
  }

  /*
   * The Buck2 controls the core voltage, set to appropriate trim value
   */
  command error_t PMIC.setCoreVoltage(uint8_t trimValue) {
    writePMIC(PMIC_BUCK2_REG1, (trimValue & B2R1_TRIM_MASK) | B2R1_GO);
    return SUCCESS;
  }
  
  command error_t PMIC.shutDownLDOs() {
    uint8_t temp;
    uint8_t oldVal, newVal;
    /* 
     * Shut down all LDOs that are not controlled by the sleep mode
     * Note, we assume here the LDO10 & LDO11 (sensor board) will be off
     * Should be moved to sensor board control
     */

    // LDO1, LDO4, LDO6, LDO7, LDO8, LDO9, LDO10, LDO 11, LDO13, LDO14

    readPMIC(PMIC_A_REG_CONTROL_1, &oldVal, 1);
    newVal = oldVal & ~ARC1_LDO13_EN & ~ARC1_LDO14_EN;
    newVal = newVal & ~ARC1_LDO10_EN & ~ARC1_LDO11_EN;	// sensor board
    writePMIC(PMIC_A_REG_CONTROL_1, newVal);

    readPMIC(PMIC_B_REG_CONTROL_1, &oldVal, 1);
    newVal = oldVal & ~BRC1_LDO1_EN & ~BRC1_LDO4_EN & ~BRC1_LDO5_EN &
             ~BRC1_LDO6_EN & ~BRC1_LDO7_EN;
    writePMIC(PMIC_B_REG_CONTROL_1, newVal);

    readPMIC(PMIC_B_REG_CONTROL_2, &oldVal, 1);
    newVal = oldVal & ~BRC2_LDO8_EN & ~BRC2_LDO9_EN & ~BRC2_LDO10_EN &
             ~BRC2_LDO11_EN & ~BRC2_LDO14_EN & ~BRC2_SIMCP_EN;
    writePMIC(PMIC_B_REG_CONTROL_2, newVal);
    
    return SUCCESS;
  }

  error_t getPMICADCVal(uint8_t channel, uint8_t *val){
    uint8_t oldval;
    error_t rval;
    
    //read out the old value so that we can reset at the end
    rval= readPMIC(PMIC_ADC_MAN_CONTROL, &oldval,1);
    rcombine(rval,writePMIC(PMIC_ADC_MAN_CONTROL, PMIC_AMC_ADCMUX(channel) | 
                  PMIC_AMC_MAN_CONV | PMIC_AMC_LDO_INT_Enable));
    rcombine(rval, readPMIC(PMIC_MAN_RES,val,1));
    //reset to old state
    rcombine(rval,writePMIC(PMIC_ADC_MAN_CONTROL, oldval));
    return rval;
  }

  command error_t PMIC.getBatteryVoltage(uint8_t *val){
    //for now, let's use the manual conversion mode
    return getPMICADCVal(0, val);
  }
  
  command error_t PMIC.chargingStatus(uint8_t *vBat, uint8_t *vChg, 
                                       uint8_t *iChg){
    getPMICADCVal(0, vBat);
    getPMICADCVal(2, vChg);
    getPMICADCVal(1, iChg);
    return SUCCESS;
  }  
  
  command error_t PMIC.enableAutoCharging(bool enable){
    return SUCCESS;
  }
  
  command error_t PMIC.enableManualCharging(bool enable){
    //just turn on or off the LED for now!!
    uint8_t val;
    
    if(enable){
      //want to turn on the charger
      getPMICADCVal(2, &val);
      //if charger is present due some stuff...75 should be 4.65V or so 
      if(val > 75 ) {
	trace(DBG_USR1,"Charger Voltage is %.3fV...enabling charger...\r\n", ((val*6) * .01035));
	//write the total timeout to be 8 hours
	writePMIC(PMIC_TCTR_CONTROL,8);
	//enable the charger at 100mA and 4.35V
	writePMIC(PMIC_CHARGE_CONTROL,PMIC_CC_CHARGE_ENABLE | PMIC_CC_ISET(1) | PMIC_CC_VSET(7));
	//turn on the LED
	writePMIC(PMIC_LED1_CONTROL,0x80);
	//start a timer to monitor our progress every 5 minutes!
	call chargeMonitorTimer.start(TIMER_REPEAT,300000);
      }
      else{
	trace(DBG_USR1,"Charger Voltage is %.3fV...charger not enabled\r\n", ((val*6) * .01035));
      }
    }
    else{
      //turn off the charger and the LED
      call PMIC.getBatteryVoltage(&val);
      trace(DBG_USR1,"Disabling Charger...Battery Voltage is %.3fV\r\n", (val * .01035) + 2.65);
      //disable everything that we enabled
      writePMIC(PMIC_TCTR_CONTROL,0);
      writePMIC(PMIC_CHARGE_CONTROL,0);
      writePMIC(PMIC_LED1_CONTROL,0x00);
    }
    return SUCCESS; 
  }  
  
  event error_t chargeMonitorTimer.fired(){
    uint8_t val;
    call PMIC.getBatteryVoltage(&val);
    //stop when vBat>4V
    if(val>130){
      call PMIC.enableManualCharging(FALSE);
      call chargeMonitorTimer.stop();
    }
    return SUCCESS;
  }
#endif
#if 0  
  command BluSH_result_t BatteryVoltage.getName(char *buff, uint8_t len){
    
    const char name[] = "BatteryVoltage";
    strcpy(buff,name);
    return BLUSH_SUCCESS_DONE;
  }
  
  command BluSH_result_t BatteryVoltage.callApp(char *cmdBuff, uint8_t cmdLen,
					      char *resBuff, uint8_t resLen){
    uint8_t val;
    if(call PMIC.getBatteryVoltage(&val)){
      trace(DBG_USR1,"Battery Voltage is %.3fV\r\n", (val * .01035) + 2.65);
    }
    else{
      trace(DBG_USR1,"Error:  getBatteryVoltage failed\r\n");
    }
    return BLUSH_SUCCESS_DONE;
  }

  command BluSH_result_t ChargingStatus.getName(char *buff, uint8_t len){
    
    const char name[] = "ChargingStatus";
    strcpy(buff,name);
    return BLUSH_SUCCESS_DONE;
  }
  
  command BluSH_result_t ChargingStatus.callApp(char *cmdBuff, uint8_t cmdLen,
					      char *resBuff, uint8_t resLen){
    uint8_t vBat, vChg, iChg;
    call PMIC.chargingStatus(&vBat, &vChg, &iChg);
    trace(DBG_USR1,"vBat = %.3fV %vChg = %.3fV iChg = %.3fA\r\n", (vBat * .01035) + 2.65,((vChg*6) * .01035), ((iChg * .01035)/1.656));
    return BLUSH_SUCCESS_DONE;
  }

  command BluSH_result_t ManualCharging.getName(char *buff, uint8_t len){
    
    const char name[] = "ManualCharging";
    strcpy(buff,name);
    return BLUSH_SUCCESS_DONE;
  }
  
  command BluSH_result_t ManualCharging.callApp(char *cmdBuff, uint8_t cmdLen,
					      char *resBuff, uint8_t resLen){
    uint8_t val;
    //get charger's state
    readPMIC(PMIC_CHARGE_CONTROL,&val, 1);
    if(val > 0){
      //charge is already enabled...disable it
      call PMIC.enableManualCharging(FALSE);
    }
    else{
       call PMIC.enableManualCharging(TRUE);
    }
    return BLUSH_SUCCESS_DONE;
  }

  command BluSH_result_t AutoCharging.getName(char *buff, uint8_t len){
    
    const char name[] = "AutoCharging";
    strcpy(buff,name);
    return BLUSH_SUCCESS_DONE;
  }
  
  command BluSH_result_t AutoCharging.callApp(char *cmdBuff, uint8_t cmdLen,
					      char *resBuff, uint8_t resLen){
    
    return BLUSH_SUCCESS_DONE;
  }
#endif
}
