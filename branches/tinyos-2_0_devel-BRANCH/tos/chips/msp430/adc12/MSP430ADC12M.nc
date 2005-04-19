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
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, 
 * OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY 
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT 
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE 
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * - Revision -------------------------------------------------------------
 * $Revision: 1.1.2.1 $
 * $Date: 2005-04-19 20:59:37 $
 * @author: Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */
includes MSP430ADC12;

module MSP430ADC12M 
{
  provides {
		interface StdControl;
    interface MSP430ADC12Single as ADCSingle[uint8_t id];
    interface MSP430ADC12Multiple as ADCMultiple[uint8_t id];
	}
	uses {
	  interface HPLADC12;
    interface RefVolt;
    interface MSP430Timer as TimerA;
    interface MSP430TimerControl as ControlA0;
    interface MSP430TimerControl as ControlA1;
    interface MSP430Compare as CompareA0;
    interface MSP430Compare as CompareA1;
	}
}
implementation
{  
  #define CHECKARGS 1
  
  norace uint8_t cmode;             /* current conversion mode */
  norace uint16_t *bufPtr;          /* result buffer */
  norace uint16_t bufLength;        /* length of buffer */
  norace uint16_t bufOffset;        /* offset into buffer */
  norace uint8_t owner;             /* interface instance for current conversion */
  norace uint8_t reserved;          /* reserve() called successfully */
  norace uint8_t vrefWait;          /* waiting for voltage generator to become stable */
  norace adc12settings_t adc12settings[uniqueCount("MSP430ADC12")]; /* bind settings */
  
  command result_t StdControl.init()
  { 
    cmode = ADC_IDLE;
    reserved = ADC_IDLE;
    vrefWait = FALSE;
    call HPLADC12.disableConversion();
    call HPLADC12.setIEFlags(0x0000);       
    return SUCCESS;
  }
  
  command result_t StdControl.start()
  {
    return SUCCESS; 
  }
  
  command result_t StdControl.stop()
  {
    call HPLADC12.disableConversion();
    call HPLADC12.setIEFlags(0x0000);
    return SUCCESS;
  }
  
  command result_t ADCSingle.bind[uint8_t num](MSP430ADC12Settings_t settings)
  {
    result_t res = FAIL;
    adc12memctl_t memctl = {  inch: settings.inputChannel,
                              sref: settings.referenceVoltage,
                              eos: 0 };
    #if CHECKARGS
    if (num >= uniqueCount("MSP430ADC12"))
      return FAIL;
    #endif
    atomic 
    {
      if (cmode == ADC_IDLE || owner != num){
        adc12settings[num].refVolt2_5 = settings.refVolt2_5;
        adc12settings[num].gotRefVolt = 0;
        adc12settings[num].clockSourceSHT = settings.clockSourceSHT;
        adc12settings[num].clockSourceSAMPCON = settings.clockSourceSAMPCON;   
        adc12settings[num].clockDivSAMPCON = settings.clockDivSAMPCON;
        adc12settings[num].clockDivSHT = settings.clockDivSHT;
        adc12settings[num].sampleHoldTime = settings.sampleHoldTime;
        adc12settings[num].memctl = memctl;
        res = SUCCESS;
      }
    }
    return res;
  }

  command result_t ADCMultiple.bind[uint8_t num](MSP430ADC12Settings_t settings)
  {
    return (call ADCSingle.bind[num](settings));
  }

  msp430ADCresult_t getRefVolt(uint8_t num)
  {
    msp430ADCresult_t adcResult = MSP430ADC12_SUCCESS;
    result_t vrefResult;
    adc12memctl_t memctl = adc12settings[num].memctl;
    
    if (memctl.sref == REFERENCE_VREFplus_AVss ||
        memctl.sref == REFERENCE_VREFplus_VREFnegterm)
    {
      if(adc12settings[num].gotRefVolt == 0) {
        if (adc12settings[num].refVolt2_5)
          vrefResult = call RefVolt.get(REFERENCE_2_5V);
        else
          vrefResult = call RefVolt.get(REFERENCE_1_5V);
      } else 
        vrefResult = SUCCESS;
      if (vrefResult != SUCCESS)
      {
        adcResult = MSP430ADC12_FAIL;
      } else {
        adc12settings[num].gotRefVolt = 1;
        if (call RefVolt.getState() == REFERENCE_UNSTABLE)
          adcResult = MSP430ADC12_DELAYED;
      }
    }
    return adcResult;
  }
    
  result_t releaseRefVolt(uint8_t num)
  {
    if (adc12settings[num].gotRefVolt == 1){
      call RefVolt.release();
      adc12settings[num].gotRefVolt = 0;
      return SUCCESS;
    }
    return FAIL;
  }

  void prepareTimerA(uint16_t interval, uint16_t csSAMPCON, uint16_t cdSAMPCON)
  {
    MSP430CompareControl_t ccResetSHI = {
      ccifg : 0, cov : 0, out : 0, cci : 0, ccie : 0,
      outmod : 0, cap : 0, clld : 0, scs : 0, ccis : 0, cm : 0 };

    call TimerA.setMode(MSP430TIMER_STOP_MODE);
    call TimerA.clear();
    call TimerA.disableEvents();
    call TimerA.setClockSource(csSAMPCON);
    call TimerA.setInputDivider(cdSAMPCON);
    call ControlA0.setControl(ccResetSHI);
    call CompareA0.setEvent(interval-1);
    call CompareA1.setEvent((interval-1)/2);
  }
    
  void startTimerA()
  {
    MSP430CompareControl_t ccSetSHI = {
      ccifg : 0, cov : 0, out : 1, cci : 0, ccie : 0,
      outmod : 0, cap : 0, clld : 0, scs : 0, ccis : 0, cm : 0 };
    MSP430CompareControl_t ccResetSHI = {
      ccifg : 0, cov : 0, out : 0, cci : 0, ccie : 0,
      outmod : 0, cap : 0, clld : 0, scs : 0, ccis : 0, cm : 0 };
    MSP430CompareControl_t ccRSOutmod = {
      ccifg : 0, cov : 0, out : 0, cci : 0, ccie : 0,
      outmod : 7, cap : 0, clld : 0, scs : 0, ccis : 0, cm : 0 };
    // manually trigger first conversion, then switch to Reset/set mode
    call ControlA1.setControl(ccResetSHI);
    call ControlA1.setControl(ccSetSHI);   
    //call ControlA1.setControl(ccResetSHI); 
    call ControlA1.setControl(ccRSOutmod);
    call TimerA.setMode(MSP430TIMER_UP_MODE); // go!
  }    
 
  msp430ADCresult_t newRequest(uint8_t req, uint8_t num, void *dataDest, uint16_t length, uint16_t jiffies)
  {
    bool access = FALSE;
    msp430ADCresult_t res = MSP430ADC12_FAIL;
    // Workaround by Cory Sharp
    // since msp430 is a 16-bit platform, make num a signed
    // 16-bit integer to avoid "warning: comparison is always true due to
    // limited range of data type" if it happens that (num >= 0) is tested.
    const int16_t num16 = num;
    
    #if CHECKARGS
    if ( num16 >= uniqueCount("MSP430ADC12") || (!reserved &&
        (!length || (req == REPEAT_SEQUENCE_OF_CHANNELS && length > 16)) ) )
      return MSP430ADC12_FAIL;
    
    // since timerA is used in upmode with OUTMOD=7, i.e. reset/set,
    // jiffies cannot be 1 (otherwise reset and set is performed simultanously).
    // it cannot be 2 either - TAR rollover with TACCR1=0 
    // does reset OUT0 signal. But with timerA running at
    // 1MHz jiffies < 10 will probably (depending on ADC12CLK) not work 
    // anyway because of too long sample-hold-time. 
    if (jiffies == 1 || jiffies == 2)
      return MSP430ADC12_FAIL;
    #endif
     
    if (reserved & RESERVED)
      if (!(reserved & VREF_WAIT) && owner == num16 && cmode == req){
        call HPLADC12.startConversion();
        if (reserved & TIMER_USED)
          startTimerA(); // go!
        reserved = ADC_IDLE;
        return MSP430ADC12_SUCCESS;
      } else
        return MSP430ADC12_FAIL;
   
    atomic {
      if (cmode == ADC_IDLE){
        owner = num16;
        cmode = SEQUENCE_OF_CHANNELS;
        access = TRUE;
      }
    }

    if (access){
      res = MSP430ADC12_SUCCESS;
      switch (getRefVolt(num16))
      {
        case MSP430ADC12_FAIL: 
          cmode = ADC_IDLE;
          res = MSP430ADC12_FAIL;
          break;
        case MSP430ADC12_DELAYED:
          // VREF is unstable, simulate reserve call and
          // start conversion in RefVolt.isStable later
          req |= (RESERVED | VREF_WAIT);
          res = MSP430ADC12_DELAYED;               
          vrefWait = TRUE;
          // fall through
        case MSP430ADC12_SUCCESS: 
          {
            int8_t i, memctlsUsed = length;
            uint16_t mask = 1;
            adc12memctl_t lastMemctl = adc12settings[num16].memctl;
            uint16_t ctl0 = ADC12CTL0_TIMER_TRIGGERED;
            adc12ctl1_t ctl1 = {adc12busy:0, conseq:1, 
                                adc12ssel:adc12settings[num16].clockSourceSHT, 
                                adc12div:adc12settings[num16].clockDivSHT, issh:0, shp:1, 
                                shs:1, cstartadd:0};
            if (length > 16){
              ctl1.conseq = 3; // repeat sequence mode
              memctlsUsed = 16;
            }
            bufPtr = dataDest;
            bufLength = length;
            bufOffset = 0;     
            
            // initialize ADC registers
            call HPLADC12.disableConversion();            
            if (jiffies == 0){
              ctl0 = ADC12CTL0_AUTO_TRIGGERED;
              ctl1.shs = 0;  // ADC12SC starts the conversion
            }
            for (i=0; i<memctlsUsed-1; i++)
              call HPLADC12.setMemControl(i, adc12settings[num16].memctl);
            lastMemctl.eos = 1;  
            call HPLADC12.setMemControl(i, lastMemctl);
            call HPLADC12.setSHT(adc12settings[num16].sampleHoldTime);
            call HPLADC12.setIEFlags(mask << i);
            call HPLADC12.setControl0_IgnoreRef(*(adc12ctl0_t*) &ctl0);
            
            if (req & SINGLE_CHANNEL){
                ctl1.conseq = 0; // single channel single conversion
                cmode = SINGLE_CHANNEL;
            } else if (req & REPEAT_SINGLE_CHANNEL){
                ctl1.conseq = 2; // repeat single channel
                cmode = REPEAT_SINGLE_CHANNEL;
            } else if (req & REPEAT_SEQUENCE_OF_CHANNELS){
                ctl1.conseq = 3; // repeat sequence of channels
                cmode = REPEAT_SEQUENCE_OF_CHANNELS;
            }
            call HPLADC12.setControl1(ctl1);
            
            if (req & RESERVED){
              // reserve ADC now
              reserved = req;
              if (jiffies != 0){
                prepareTimerA(jiffies, adc12settings[num16].clockSourceSAMPCON,
                                adc12settings[num16].clockDivSAMPCON);
                reserved |= TIMER_USED;
              }
            } else {
               // trigger first conversion now
               call HPLADC12.startConversion();
               if (jiffies != 0){
                 prepareTimerA(jiffies, adc12settings[num16].clockSourceSAMPCON,
                               adc12settings[num16].clockDivSAMPCON);
                 startTimerA(); // go!
               }
            }
            res = MSP430ADC12_SUCCESS;
            break;
          }
      } // of switch
    }
    return res;
  }

  
  result_t unreserve(uint8_t num)
  {
    if (reserved & RESERVED && owner == num){
      cmode = reserved = ADC_IDLE;
      return SUCCESS;
    }
    return FAIL;
  }
  
  async command msp430ADCresult_t ADCSingle.getData[uint8_t num]()
  {
    return newRequest(SINGLE_CHANNEL, num, 0, 1, 0);
  }

  async command msp430ADCresult_t ADCSingle.getDataRepeat[uint8_t num](uint16_t jiffies)
  {
    return newRequest(REPEAT_SINGLE_CHANNEL, num, 0, 1, jiffies);
  }

  async command result_t ADCSingle.reserve[uint8_t num]()
  {
    if (newRequest(RESERVED | SINGLE_CHANNEL, num, 0, 1, 0) == MSP430ADC12_SUCCESS)
      return SUCCESS;
    return FAIL;
  }

  async command result_t ADCSingle.reserveRepeat[uint8_t num](uint16_t jiffies)
  {
    if (newRequest(RESERVED | REPEAT_SINGLE_CHANNEL, num, 0, 1, jiffies) == 
        MSP430ADC12_SUCCESS)
      return SUCCESS;
    return FAIL;
  }

  async command result_t ADCSingle.unreserve[uint8_t num]()
  {
    return unreserve(num);
  }
  
  async command msp430ADCresult_t ADCMultiple.getData[uint8_t num](uint16_t *buf, 
                                             uint16_t length, uint16_t jiffies)
  {
    return newRequest(SEQUENCE_OF_CHANNELS, num, buf, length, jiffies);
  }
  
  async command msp430ADCresult_t ADCMultiple.getDataRepeat[uint8_t num](uint16_t *buf, 
                                             uint8_t length, uint16_t jiffies) 
  {
    return newRequest(REPEAT_SEQUENCE_OF_CHANNELS, num, buf, length, jiffies);
  }

  async command result_t ADCMultiple.reserve[uint8_t num](uint16_t *buf, 
                                      uint16_t length, uint16_t jiffies)
  {
    if (newRequest(SEQUENCE_OF_CHANNELS | RESERVED, num, buf, length, jiffies)
        == MSP430ADC12_SUCCESS)
      return SUCCESS;
    return FAIL;
  }
  
  async command result_t ADCMultiple.reserveRepeat[uint8_t num](uint16_t *buf,
                                            uint16_t length, uint16_t jiffies)
  {
    if (newRequest(REPEAT_SEQUENCE_OF_CHANNELS | RESERVED, num, buf, length, jiffies)
        == MSP430ADC12_SUCCESS)
      return SUCCESS;
    return FAIL;
  }
  
  async command result_t  ADCMultiple.unreserve[uint8_t num]()
  {
    return unreserve(num);
  }
     
  async event void TimerA.overflow(){}
  async event void CompareA0.fired(){}
  async event void CompareA1.fired(){}

  default async event result_t ADCSingle.dataReady[uint8_t num](uint16_t data)
  {
    return FAIL;
  }
  default async event uint16_t* ADCMultiple.dataReady[uint8_t num](uint16_t *buf,
                                                          uint16_t length)
  {
    return (uint16_t*) 0;
  }

  event void RefVolt.isStable(RefVolt_t vref)
  {
    if (vrefWait){
      call HPLADC12.startConversion();
      if (reserved & TIMER_USED)
        startTimerA(); // go!
      reserved = ADC_IDLE;
      vrefWait = FALSE;
    }
  }
    
  void stopConversion()
  {
    call TimerA.setMode(MSP430TIMER_STOP_MODE);
    call HPLADC12.stopConversion();
    call HPLADC12.setIEFlags(0);
    call HPLADC12.resetIFGs();
    if (adc12settings[owner].gotRefVolt)
      releaseRefVolt(owner);
    cmode = ADC_IDLE;  // enable access to ADC, owner now invalid
  }
  
  async event void HPLADC12.converted(uint8_t number){
    switch (cmode) 
    { 
       case SINGLE_CHANNEL:
            {
              volatile uint8_t ownerTmp = owner;
              stopConversion();
              signal ADCSingle.dataReady[ownerTmp](call HPLADC12.getMem(0));
            }
            break;
       case REPEAT_SINGLE_CHANNEL:
            if (signal ADCSingle.dataReady[owner](call HPLADC12.getMem(0)) == FAIL)
              stopConversion();
            break;
        case SEQUENCE_OF_CHANNELS:
            {
              uint16_t i = 0, length = (bufLength - bufOffset > 16) ? 16 : bufLength - bufOffset;
              do {
                *bufPtr++ = call HPLADC12.getMem(i);
              } while (++i < length);
               
              bufOffset += length;
              
              if (bufLength - bufOffset > 15)
                return;
              else if (bufLength - bufOffset > 0){
                adc12memctl_t memctl = call HPLADC12.getMemControl(0);
                memctl.eos = 1;
                call HPLADC12.setMemControl(bufLength - bufOffset, memctl);
              } else {
                stopConversion();
                signal ADCMultiple.dataReady[owner](bufPtr - bufLength, bufLength);
              }
            }
            break;
        case REPEAT_SEQUENCE_OF_CHANNELS:
            {
              uint8_t i = 0;
              do {
                *bufPtr++ = call HPLADC12.getMem(i);
              } while (++i < bufLength);
              if ((bufPtr = signal ADCMultiple.dataReady[owner](bufPtr-bufLength,
                        bufLength)) == 0)
                stopConversion();
              break;
            }
        default:
            {
              //volatile uint16_t data = call HPLADC12.getMem(number);
              call HPLADC12.resetIFGs();
            }
            break;
      } // switch
  }
  
  async event void HPLADC12.memOverflow(){}
  async event void HPLADC12.timeOverflow(){}

}

