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
 * $Revision: 1.1.2.2 $
 * $Date: 2006-01-12 18:05:03 $
 * @author: Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */

module AdcC {
  provides {
    interface Read<uint16_t> as Read[uint8_t client];
    interface ReadNow<uint16_t> as ReadNow[uint8_t client];
    //interface ReadStream<uint16_t> as ReadStream[uint8_t client];
  }
  uses {
    interface Msp430Adc12SingleChannel as SingleChannel[uint8_t client];
    interface Msp430Adc12Config as Config[uint8_t client];
    interface Resource as ResourceRead[uint8_t client];
    interface Resource as ResourceReadNow[uint8_t client];
    //interface Resource as ResourceReadStream[uint8_t client];
  }
}
implementation
{
  enum { // state
    READ,
    READ_NOW,
    READ_STREAM
  };
  
  // Resource interface makes norace safe
  norace uint8_t state;
  norace uint8_t owner;
  norace uint16_t value;
    
  error_t getSingleData(uint8_t client) 
  {
    msp430adc12_channel_config_t settings;
    msp430adc12_result_t result;
    
    settings = call Config.getChannelSettings[client]();
    if (settings.inch == INPUT_CHANNEL_NONE)
      return EINVAL;
    result = call SingleChannel.getSingleData[client](&settings);
    if (result == MSP430ADC12_SUCCESS || result == MSP430ADC12_DELAYED)
      return SUCCESS;
    else
      return EBUSY;
  }
  
  command error_t Read.read[uint8_t client]()
  {
    return call ResourceRead.request[client]();
  }

  event void ResourceRead.granted[uint8_t client]() 
  {
    msp430adc12_result_t result = getSingleData(client);
    if (result == SUCCESS){
      state = READ;
      owner = client;
    } else
      signal Read.readDone[client](FAIL, 0);
  }
  
  async command error_t ReadNow.read[uint8_t client]()
  {
    return call ResourceReadNow.request[client]();
  }

  event void ResourceReadNow.granted[uint8_t client]() 
  {
    error_t result = getSingleData(client);
    if (result == SUCCESS)
      state = READ_NOW;
    else
      signal ReadNow.readDone[client](FAIL, 0);
  }
  
  void task readDone()
  {
    call ResourceRead.release[owner]();
    signal Read.readDone[owner](SUCCESS, value);
  }

  async event error_t SingleChannel.singleDataReady[uint8_t client](uint16_t data)
  {
    switch (state)
    {
      case READ:
        value = data;
        post readDone();
        break;
      case READ_NOW:  
        call ResourceReadNow.release[client]();
        signal ReadNow.readDone[client](SUCCESS, data);
        break;
      case READ_STREAM:
        break;
      default:
        break;
    }
    return SUCCESS;
  }
  
  async event uint16_t* SingleChannel.multipleDataReady[uint8_t client](
      uint16_t *buf, uint16_t length)
  {
    return 0;
  }
  
  default async command error_t ResourceRead.request[uint8_t client]() { return FAIL; }
  default async command void ResourceRead.release[uint8_t client]() { }
  default event void Read.readDone[uint8_t client]( error_t result, uint16_t val ){}
  
  default async command error_t ResourceReadNow.request[uint8_t client]() { return FAIL; }
  default async command void ResourceReadNow.release[uint8_t client]() { }
  default async event void ReadNow.readDone[uint8_t client]( error_t result, uint16_t val ){}

  default async command msp430adc12_result_t 
    SingleChannel.getSingleData[uint8_t client](const msp430adc12_channel_config_t *config)
  {
    return MSP430ADC12_FAIL_PARAMS;
  }

  default async command msp430adc12_channel_config_t 
    Config.getChannelSettings[uint8_t client]()
  { 
    msp430adc12_channel_config_t defaultConfig = {INPUT_CHANNEL_NONE,0,0,0,0,0,0,0}; 
    return defaultConfig;
  }
}

