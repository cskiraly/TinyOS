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
 * $Revision: 1.1.2.4 $
 * $Date: 2005-06-03 01:43:32 $
 * @author: Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */

includes MSP430ADC12;
module MSP430ADC12M 
{
  provides {
    interface MSP430ADC12SingleChannel as SingleChannel[uint8_t id];
	}
	uses {
    interface ResourceUser as ADCResourceUser;
    interface RefVoltGenerator;
	  interface HPLADC12;
    interface MSP430Timer as TimerA;
    //interface Resource as TimerAResource;
    interface MSP430TimerControl as ControlA0;
    interface MSP430TimerControl as ControlA1;
    interface MSP430Compare as CompareA0;
    interface MSP430Compare as CompareA1;
	}
}
implementation
{ 
  enum { // mode
    SINGLE_DATA,
    SINGLE_DATA_REPEAT,
    MULTIPLE_DATA,
    MULTIPLE_DATA_REPEAT,
  };
  enum { // flagsADC
    ADC_BUSY = 1,               /* request pending */
    TIMERA_USED = 2,            /* TimerA used for SAMPCON signal */
    VREF_USED = 4,              /* VREF generator in use */
  };

  // norace is safe, because Resource interface resolves conflicts  
  norace uint16_t *bufPtr;          /* result buffer */
  norace uint16_t bufLength;        /* length of buffer */
  norace uint16_t bufOffset;        /* offset into buffer */
  norace uint8_t clientID;          /* ID of interface that issued current request */
  norace uint8_t mode;              /* current conversion mode, see above */
  norace uint8_t flagsADC;          /* current state, see above */
  
  msp430adc12_result_t checkGetRefVolt(uint8_t referenceVoltage, uint8_t refVolt2_5);
  error_t checkReleaseRefVolt();
  void prepareTimerA(uint16_t interval, uint16_t csSAMPCON, uint16_t cdSAMPCON);
  void startTimerA();
  void configureAdcPin( uint8_t inputChannel );

  
  msp430adc12_result_t newRequest(uint8_t req, msp430adc12_channel_config_t configData,
      void *dest, uint16_t length, uint16_t jiffies)
  {
    msp430adc12_result_t result;
    
    // Since timerA is used in upmode with OUTMOD=7, i.e. reset/set,
    // jiffies cannot be 1 (otherwise reset and set is performed simultanously).
    // Jiffies cannot be 2 either - TAR rollover with TACCR1=0 
    // does reset OUT0 signal. If jiffies = 0, then repeat mode is chosen.
    // Note: With timerA running at 1MHz jiffies < 10 will probably 
    // (depending on ADC12CLK) not work, because of too long sample-hold-time. 
    if (jiffies){
      // TODO: get TimerA by arbitration
      flagsADC |= TIMERA_USED;
      if (jiffies == 1 || jiffies == 2)
        return MSP430ADC12_FAIL_JIFFIES;
    }
    mode = req;
     
    switch (result = checkGetRefVolt(configData.referenceVoltage, configData.refVolt2_5))
    {
      case MSP430ADC12_FAIL_VREF: 
        break;
      case MSP430ADC12_DELAYED:
        // VREF is still unstable, setup registers now and start
        // conversion in RefVoltGenerator.isStable event handler later
        // fall through
      case MSP430ADC12_SUCCESS: 
        {
          adc12ctl0_t ctl0 = { 
            adc12sc:0, enc:0, adc12tovie:0, 
            adc12ovie:0, adc12on:1, 
            refon: call HPLADC12.getRefon(), 
            r2_5v: call HPLADC12.getRef2_5V(),
            msc: (jiffies == 0) ? 1 : 0, 
            sht0:configData.sampleHoldTime, 
            sht1:configData.sampleHoldTime
          };
          adc12ctl1_t ctl1 = {
            adc12busy:0, 
            conseq:0, // will be changed later
            adc12ssel:configData.clockSourceSHT, 
            adc12div:configData.clockDivSHT, 
            issh:0, shp:1, 
            shs: (jiffies == 0) ? 0 : 1,
            cstartadd:0
          };
          adc12memctl_t memctl = {
            inch: configData.inputChannel,
            sref: configData.referenceVoltage,
            eos: 0
          };
          uint16_t i, mask = 1;

          bufPtr = dest;
          bufLength = length;
          bufOffset = 0;            
          switch (req)
          {
            case SINGLE_DATA:
              ctl1.conseq = 0;
              break;
            case SINGLE_DATA_REPEAT:
              ctl1.conseq = 2;
              break;
            case MULTIPLE_DATA:
              if (length > 16)
                ctl1.conseq = 3;
              else
                ctl1.conseq = 1;
              break;
            case MULTIPLE_DATA_REPEAT:
              ctl1.conseq = 3;
              break;
          }
          
          configureAdcPin( configData.inputChannel );
          call HPLADC12.disableConversion();
          call HPLADC12.setControl0(ctl0);
          call HPLADC12.setControl1(ctl1);
          for (i=0; i<(length-1) && i < 15; i++)
            call HPLADC12.setMemControl(i, memctl);
          memctl.eos = 1;  
          call HPLADC12.setMemControl(i, memctl);
          call HPLADC12.setIEFlags(mask << i);
          
          if (jiffies)
            prepareTimerA(jiffies, configData.clockSourceSAMPCON,
                          configData.clockDivSAMPCON);
          
          if (result == MSP430ADC12_SUCCESS){ // VREF stable or unused
            call HPLADC12.startConversion();
            if (jiffies)
              startTimerA(); // go!
          }
          break;
        }
      default:
        break;
    } // of switch
    return result;
  }

  error_t getAndSetBusy()
  {
    uint8_t oldFlags;
    atomic {
      oldFlags = flagsADC;
      flagsADC |= ADC_BUSY;
    }
    if (oldFlags & ADC_BUSY)
      return FAIL;
    else
      return SUCCESS;
  }

  msp430adc12_result_t getAccess(uint8_t id)
  {
    if (call ADCResourceUser.user() == id){
      if (getAndSetBusy() == FAIL)
        return MSP430ADC12_FAIL_BUSY;
      clientID = id;
      return MSP430ADC12_SUCCESS;
    }
    return MSP430ADC12_FAIL_NOT_RESERVED;
  }

  async command msp430adc12_result_t SingleChannel.getSingleData[uint8_t id]()
  {
    msp430adc12_result_t access = getAccess(id);
    if (access == MSP430ADC12_SUCCESS)
      return newRequest(SINGLE_DATA, 
                        signal SingleChannel.getConfigurationData[id](), 
                        0, 1, 0);
    else
      return access;
  }

  async command msp430adc12_result_t SingleChannel.getSingleDataRepeat[uint8_t id](
      uint16_t jiffies)
  {
    msp430adc12_result_t access = getAccess(id);
    if (access == MSP430ADC12_SUCCESS)
      return newRequest(SINGLE_DATA_REPEAT,
                        signal SingleChannel.getConfigurationData[id](),
                        0, 1, jiffies);
    else
      return access;
  }

  async command msp430adc12_result_t SingleChannel.getMultipleData[uint8_t id](
      uint16_t *buf, uint16_t length, uint16_t jiffies)
  {
    msp430adc12_result_t access = getAccess(id);
    if (access == MSP430ADC12_SUCCESS)
      return newRequest(MULTIPLE_DATA,
                        signal SingleChannel.getConfigurationData[id](),
                        buf, length, jiffies);
    else
      return access;
  }

  async command msp430adc12_result_t SingleChannel.getMultipleDataRepeat[uint8_t id](
      uint16_t *buf, uint8_t length, uint16_t jiffies)
  {
    msp430adc12_result_t access;
    if (length > 16)
      return MSP430ADC12_FAIL_LENGTH;
    access = getAccess(id);
    if (access == MSP430ADC12_SUCCESS)
      return newRequest(MULTIPLE_DATA_REPEAT, 
                        signal SingleChannel.getConfigurationData[id](),
                        buf, length, jiffies);
    else
      return access;    
  }

  async event void TimerA.overflow(){}
  async event void CompareA0.fired(){}
  async event void CompareA1.fired(){}

  msp430adc12_result_t checkGetRefVolt(uint8_t referenceVoltage, uint8_t refVolt2_5)
  {
    error_t vrefResult;
    if (referenceVoltage == REFERENCE_VREFplus_AVss ||
        referenceVoltage == REFERENCE_VREFplus_VREFnegterm)
    {
      if (refVolt2_5 == REFVOLT_LEVEL_1_5)
        vrefResult = call RefVoltGenerator.switchOn(REFERENCE_1_5V);
      else
        vrefResult = call RefVoltGenerator.switchOn(REFERENCE_2_5V);
      if (vrefResult == FAIL)
        return MSP430ADC12_FAIL_VREF;
      else {
        flagsADC |= VREF_USED;
        if (call RefVoltGenerator.getVoltageLevel() == REFERENCE_UNSTABLE)
          return MSP430ADC12_DELAYED;
        else
          return MSP430ADC12_SUCCESS;
      }
    } else {
      flagsADC &= ~VREF_USED;
      return MSP430ADC12_SUCCESS;
    }
  }
    
  error_t checkReleaseRefVolt()
  {
    if (flagsADC & VREF_USED){
      call RefVoltGenerator.switchOff();
      flagsADC &= ~VREF_USED;
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
  
  void configureAdcPin( uint8_t inputChannel )
  {
    if( inputChannel <= 7 ){
      P6SEL |= (1 << inputChannel); //adc function (instead of general IO)
      P6DIR &= ~(1 << inputChannel); //input (instead of output)
    }
  }

  event void RefVoltGenerator.isStable(uint8_t voltageLevel)
  {
    if (flagsADC & VREF_USED){
      call HPLADC12.startConversion();
      if (flagsADC & TIMERA_USED)
        startTimerA(); // go!
    }
  }
    
  void stopConversion()
  {
    if (flagsADC & TIMERA_USED){
      call TimerA.setMode(MSP430TIMER_STOP_MODE);
      // TODO: release TimerA through arbitration
    }
    call HPLADC12.stopConversion();
    call HPLADC12.setIEFlags(0);
    call HPLADC12.resetIFGs();
    checkReleaseRefVolt();
    flagsADC &= ~ADC_BUSY;
  }
  

  
  async event void HPLADC12.conversionDone(uint16_t iv)
  {
    switch (mode) 
    { 
      case SINGLE_DATA:
        stopConversion();
        signal SingleChannel.singleDataReady[clientID](call HPLADC12.getMem(0));
        break;
      case SINGLE_DATA_REPEAT:
        {
          error_t repeatContinue;
          repeatContinue = signal SingleChannel.singleDataReady[clientID](
                call HPLADC12.getMem(0));
          if (repeatContinue == FAIL)
            stopConversion();
          break;
        }
      case MULTIPLE_DATA:
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
            signal SingleChannel.multipleDataReady[clientID](bufPtr - bufLength, bufLength);
          }
        }
        break;
      case MULTIPLE_DATA_REPEAT:
        {
          uint8_t i = 0;
          do {
            *bufPtr++ = call HPLADC12.getMem(i);
          } while (++i < bufLength);
          
          bufPtr = signal SingleChannel.multipleDataReady[clientID](bufPtr-bufLength,
                    bufLength);
          if (!bufPtr)  
            stopConversion();
          break;
        }
      } // switch
  }

  default async event msp430adc12_channel_config_t 
    SingleChannel.getConfigurationData[uint8_t id]()
  {
    msp430adc12_channel_config_t config = {0,0,0,0,0,0,0,0};
    return config;
  }
  
  default async event error_t SingleChannel.singleDataReady[uint8_t id](uint16_t data)
  {
    return FAIL;
  }
  
  default async event uint16_t* SingleChannel.multipleDataReady[uint8_t id](
      uint16_t *buf, uint16_t length)
  {
    return 0;
  }
  
  async event void HPLADC12.memOverflow(){}
  async event void HPLADC12.timeOverflow(){}

}

