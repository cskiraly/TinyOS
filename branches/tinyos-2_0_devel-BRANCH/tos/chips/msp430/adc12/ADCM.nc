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
 * $Revision: 1.1.2.3 $
 * $Date: 2005-06-08 08:08:16 $
 * @author: Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */

module ADCM {
  provides {
    interface StdControl as StdControlNull;
    interface Resource as ResourceHAL2[uint8_t client];
    interface AcquireData[uint8_t port];
    interface AcquireDataNow[uint8_t port];
    interface AcquireDataBuffered[uint8_t port];  
    interface MSP430ADC12ChannelConfig as ChannelConfig;
  }
  uses {
    interface Resource as ResourceHAL1;
    interface MSP430ADC12SingleChannel as SingleChannel;
  }
}
implementation
{
  enum {
    ACQUIRE_DATA,
    ACQUIRE_DATA_NOW,
    ACQUIRE_DATA_BUFFERED
  };
  msp430adc12_channel_config_t channelConfig;
  uint8_t request;
  uint8_t currentClientID;
  uint16_t conversionResult;
  uint16_t *m_buffer; // for AcquireDataBuffered
  uint16_t m_count;   // for AcquireDataBuffered
  uint32_t m_rate;    // for AcquireDataBuffered
    
  void task signalSingleDataReady();
  void task signalBufferedDataReady();




  
  
  // StdControl must be provided for platform independent services
  // but there is nothing to do for it on the MSP430.
  command error_t StdControlNull.start() {
    return SUCCESS;
  }
  command error_t StdControlNull.stop() {
    return SUCCESS;
  } 
  
  async command error_t ResourceHAL2.request[uint8_t client]()
  {
    return call ResourceHAL1.request();
  }

  async command error_t ResourceHAL2.immediateRequest[uint8_t client]()
  {
    return call ResourceHAL1.immediateRequest();
  }

  async command void ResourceHAL2.release[uint8_t client]()
  {
    return;
  }

  event void ResourceHAL1.granted()
  {
    signal ResourceHAL2.granted[currentClientID]();
  }

  msp430adc12_channel_config_t getInternalChannelConfigData(uint8_t channel)
  {
    msp430adc12_channel_config_t config = {
                      channel, REFERENCE_VREFplus_AVss, REFVOLT_LEVEL_1_5,
                      SHT_SOURCE_ACLK, SHT_CLOCK_DIV_1, SAMPLE_HOLD_4_CYCLES,
                      SAMPCON_SOURCE_SMCLK, SAMPCON_CLOCK_DIV_1 };
    return config;
  }
  
  error_t getDataHAL1(uint8_t port, bool now)
  {
    msp430adc12_result_t hal1Result;
    atomic {
      if (port < 8)
        channelConfig = signal ChannelConfig.getConfigurationData(port);
      else if (port < 16)
        channelConfig = getInternalChannelConfigData(port);
      else 
        return ESIZE;
    }
    hal1Result = call SingleChannel.getSingleData();
    if (hal1Result != MSP430ADC12_SUCCESS && hal1Result != MSP430ADC12_DELAYED)
      return EBUSY;
    else {
      currentClientID = port;
      if (now)
        atomic request = ACQUIRE_DATA_NOW;
      else
        atomic request = ACQUIRE_DATA;
      return SUCCESS;
    }
  }

  command error_t AcquireData.getData[uint8_t port]()
  {
    return getDataHAL1(port, FALSE);
  }

  async command error_t AcquireDataNow.getData[uint8_t port]()
  {
    return getDataHAL1(port, TRUE);
  }

  command error_t AcquireDataBuffered.prepare[uint8_t port](uint16_t *buffer, 
      uint16_t count, uint32_t rate)
  {
    if (rate < 3 || rate > 2000000)
      return ESIZE;
    m_buffer = buffer;
    m_count = count;
    if (rate & 0xFFFF0000) //< (uint32_t) 65535)
      m_rate = rate;
    else
      m_rate = rate & 0xFFFFFFC0;
  }

  command uint32_t AcquireDataBuffered.getRate[uint8_t port]()
  {
    return m_rate;
  }

  async command error_t AcquireDataBuffered.getData[uint8_t port]()
  {
    msp430adc12_result_t hal1Result;
    atomic {
      if (port < 8)
        channelConfig = signal ChannelConfig.getConfigurationData(port);
      else if (port < 16)
        channelConfig = getInternalChannelConfigData(port);
      else 
        return ESIZE;
    }
    if (m_rate & 0xFFFF0000){
      channelConfig.sampcon_ssel = SAMPCON_SOURCE_SMCLK; // 1MHz
      channelConfig.sampcon_id = SAMPCON_CLOCK_DIV_1;
      hal1Result = call SingleChannel.getMultipleData(m_buffer, m_count, 
              (uint16_t) m_rate);
    } else {
      channelConfig.sampcon_ssel = SAMPCON_SOURCE_ACLK; // 32Khz
      channelConfig.sampcon_id = SAMPCON_CLOCK_DIV_1;
      hal1Result = call SingleChannel.getMultipleData(m_buffer, m_count, 
              m_rate >> 5);
    }
    currentClientID = port;
    if (hal1Result != MSP430ADC12_SUCCESS && hal1Result != MSP430ADC12_DELAYED)
      return EBUSY;
    else {
      atomic request = ACQUIRE_DATA_BUFFERED;
      return SUCCESS;
    }
  }

  async event error_t SingleChannel.singleDataReady(uint16_t data)
  {
    call ResourceHAL1.release();
    switch (request)
    {
      case ACQUIRE_DATA:
        conversionResult = data;
        post signalSingleDataReady();
        break;
      case ACQUIRE_DATA_NOW:  
        signal AcquireDataNow.dataReady[currentClientID](data);
        break;
      default:
        break;
    }
    return SUCCESS;
  }
  
  void task signalSingleDataReady()
  {
    signal AcquireData.dataReady[currentClientID](conversionResult);
  }
  
  async event uint16_t* SingleChannel.multipleDataReady(uint16_t *buf, uint16_t length)
  {
    call ResourceHAL1.release();
    post signalBufferedDataReady();
    return 0;
  }

  void task signalBufferedDataReady()
  {
    signal AcquireDataBuffered.dataReady[currentClientID](m_buffer, m_count);
  }

  async event msp430adc12_channel_config_t SingleChannel.getConfigurationData()
  {
    return channelConfig;
  }

  event void ResourceHAL1.requested(){}

  default event void AcquireData.dataReady[uint8_t port](uint16_t data){}
  default event void AcquireData.error[uint8_t port](uint16_t info){}
  default async event void AcquireDataNow.dataReady[uint8_t port](uint16_t data){}
  default event void AcquireDataNow.error[uint8_t port](uint16_t info){}
  default event void AcquireDataBuffered.dataReady[uint8_t port](uint16_t *buffer,
      uint16_t count){}
  default event void AcquireDataBuffered.error[uint8_t port](uint16_t info){}
  default event void ResourceHAL2.granted[uint8_t client](){}
  
}

