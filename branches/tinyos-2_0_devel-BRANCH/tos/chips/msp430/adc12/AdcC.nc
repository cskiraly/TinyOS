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
 * $Date: 2006-01-16 16:03:54 $
 * @author: Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */

module AdcC {
  provides {
    interface Init;
    interface Read<uint16_t> as Read[uint8_t client];
    interface ReadNow<uint16_t> as ReadNow[uint8_t client];
    interface ReadStream<uint16_t> as ReadStream[uint8_t rsClient];
  }
  uses {
    // for Read and ReadNow:
    interface Resource as Resource[uint8_t client];
    interface Msp430Adc12Config as Config[uint8_t client];
    interface Msp430Adc12SingleChannel as SingleChannel[uint8_t client];
    // for ReadStream:
    interface Resource as ResourceReadStream[uint8_t rsClient];
    interface Msp430Adc12Config as ConfigReadStream[uint8_t rsClient];
    interface Msp430Adc12SingleChannel as SingleChannelReadStream[uint8_t rsClient];
  }
}
implementation
{
  enum { // state
    READ,
    READ_NOW,
    READ_STREAM
  };

  struct list_entry_t {
    uint16_t count;
    struct list_entry_t *next;
  };
  
  // Resource interface makes norace safe
  norace uint8_t state;
  norace uint8_t owner;
  norace uint16_t value;
  norace bool ignore;
  norace uint16_t *resultBuf;
  struct list_entry_t *streamBuf[uniqueCount(ADCC_READ_STREAM_SERVICE)];
  uint32_t usPeriod[uniqueCount(ADCC_READ_STREAM_SERVICE)];
    
  void task failReadStreamRequest();
  void task signalBufferDone();
  void nextReadStreamRequest(uint8_t rsClient);

  command error_t Init.init()
  {
    uint16_t i;
    for (i=0; i<uniqueCount(ADCC_READ_STREAM_SERVICE); i++){
      streamBuf[i] = 0;
      usPeriod[i] = 0;
    }
    ignore = FALSE;
    state = owner = value = 0;
  }
  
  command error_t Read.read[uint8_t client]()
  {
    return call Resource.request[client]();
  }
  
  async command error_t ReadNow.read[uint8_t client]()
  {
    msp430adc12_channel_config_t settings;
    msp430adc12_result_t hal1request;
    error_t granted = call Resource.immediateRequest[client]();
    
    if (granted == SUCCESS){
      settings = call Config.getChannelSettings[client]();
      if (settings.inch == INPUT_CHANNEL_NONE){
        call Resource.release[client]();
        return EINVAL;
      }
      hal1request = call SingleChannel.getSingleData[client](&settings);
      if (hal1request == MSP430ADC12_SUCCESS){
        state = READ_NOW;
        return SUCCESS;
      } else {
        if (hal1request == MSP430ADC12_DELAYED){
          // delayed conversion not acceptable for ReadNow
          error_t stopped = call SingleChannel.stop[client]();
          if (stopped == SUCCESS){
            call Resource.release[client]();
            return EOFF;
          } else {
            // will get the singleDataReady, but have to ignore it 
            ignore = TRUE;
            return EOFF;
          }
        } else {
          call Resource.release[client]();
          return EBUSY;
        }
      }
    }
    return granted;
  }

  event void Resource.granted[uint8_t client]() 
  {
    // signalled only for Read (ReadNow uses immediateRequest)
    msp430adc12_channel_config_t settings;
    msp430adc12_result_t hal1request;
    
    settings = call Config.getChannelSettings[client]();
    if (settings.inch == INPUT_CHANNEL_NONE){
      call Resource.release[client]();
      signal Read.readDone[client](EINVAL, 0);
      return;
    }
    hal1request = call SingleChannel.getSingleData[client](&settings);
    if (hal1request == MSP430ADC12_SUCCESS || hal1request == MSP430ADC12_DELAYED){
      state = READ;
      owner = client;
    } else {
      call Resource.release[client]();
      signal Read.readDone[client](FAIL, 0);
    }
  }
  
  void task readDone()
  {
    volatile uint16_t valueTmp = value;
    call Resource.release[owner]();
    // "value" might change here
    signal Read.readDone[owner](SUCCESS, valueTmp);
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
        call Resource.release[client]();
        if (ignore == TRUE)
          ignore = FALSE;
        else
          signal ReadNow.readDone[client](SUCCESS, data);
        break;
      default:
        break;
    }
    return SUCCESS;
  }

  async event uint16_t* SingleChannel.multipleDataReady[uint8_t client](
      uint16_t *buf, uint16_t length)
  {
    // won't happen
    return 0;
  }
  
  
  command error_t ReadStream.postBuffer[uint8_t rsClient]( uint16_t* buf, uint16_t count )
  {
    struct list_entry_t *newEntry = (struct list_entry_t *) buf;
    newEntry->count = count;
    newEntry->next = streamBuf[rsClient];
    streamBuf[rsClient] = newEntry;
    return SUCCESS;
  }
  
  command error_t ReadStream.read[uint8_t rsClient]( uint32_t _usPeriod )
  {
    if (!streamBuf[rsClient])
      return EINVAL;
    usPeriod[rsClient] = _usPeriod;
    return call ResourceReadStream.request[rsClient]();
  }
  
  event void ResourceReadStream.granted[uint8_t rsClient]() 
  {
    owner = rsClient;
    nextReadStreamRequest(rsClient);
  }

  void nextReadStreamRequest(uint8_t rsClient)
  {
    msp430adc12_channel_config_t settings;
    msp430adc12_result_t hal1request;
    struct list_entry_t *entry = streamBuf[rsClient];

    if (!entry){
      // all done
      call ResourceReadStream.release[rsClient]();
      signal ReadStream.readDone[rsClient]( SUCCESS );
      return;
    }
    settings = call ConfigReadStream.getChannelSettings[rsClient]();
    if (settings.inch == INPUT_CHANNEL_NONE){
      // settings are invalid (ConfigReadStream not wired?) 
      post failReadStreamRequest();
      return;
    }
    streamBuf[rsClient] = entry->next;
    settings.sampcon_ssel = SAMPCON_SOURCE_SMCLK; // assumption: SMCLK runs at 1 MHz
    settings.sampcon_id = SAMPCON_CLOCK_DIV_1; 
    hal1request = call SingleChannelReadStream.getMultipleData[rsClient](
      &settings, (uint16_t *) entry, entry->count, usPeriod[rsClient]);
    if (hal1request != MSP430ADC12_SUCCESS && hal1request != MSP430ADC12_DELAYED){
      post failReadStreamRequest();
      return;
    }
  }

  void task failReadStreamRequest()
  {
    // return client's buffers and signal readDone with FAIL 
    struct list_entry_t *nextEntry = streamBuf[owner], *entry;
    while ((entry = nextEntry)){
      nextEntry = entry->next;
      signal ReadStream.bufferDone[owner]( EINVAL, (uint16_t *) entry, entry->count);
    }
    streamBuf[owner] = 0;
    signal ReadStream.readDone[owner]( EINVAL );
    call ResourceReadStream.release[owner]();
    return;
  }

  async event uint16_t* SingleChannelReadStream.multipleDataReady[uint8_t rsClient](
      uint16_t *buf, uint16_t length)
  {
    value = length;
    resultBuf = buf;
    post signalBufferDone();
    return 0;
  }

  void task signalBufferDone()
  {
    signal ReadStream.bufferDone[owner]( SUCCESS, resultBuf, value);
    nextReadStreamRequest(owner);
  }
  
  async event error_t SingleChannelReadStream.singleDataReady[uint8_t rsClient](uint16_t data)
  {
    // won't happen
    return SUCCESS;
  }

  default async command error_t Resource.request[uint8_t client]() { return FAIL; }
  default async command error_t Resource.immediateRequest[uint8_t client]() { return FAIL; }
  default async command void Resource.release[uint8_t client]() { }
  default event void Read.readDone[uint8_t client]( error_t result, uint16_t val ){}
  default async event void ReadNow.readDone[uint8_t client]( error_t result, uint16_t val ){}
  
  default async command error_t ResourceReadStream.request[uint8_t rsClient]() { return FAIL; }
  default async command void ResourceReadStream.release[uint8_t rsClient]() { }
  default event void ReadStream.bufferDone[uint8_t rsClient]( error_t result, 
			 uint16_t* buf, uint16_t count ){}
  default event void ReadStream.readDone[uint8_t rsClient]( error_t result ){ } 

  default async command msp430adc12_result_t 
    SingleChannel.getSingleData[uint8_t client](const msp430adc12_channel_config_t *config)
  {
    return MSP430ADC12_FAIL_PARAMS;
  }
  
  default async command error_t SingleChannel.stop[uint8_t client]()
  {
    return SUCCESS;
  }

  default async command msp430adc12_channel_config_t 
    Config.getChannelSettings[uint8_t client]()
  { 
    msp430adc12_channel_config_t defaultConfig = {INPUT_CHANNEL_NONE,0,0,0,0,0,0,0}; 
    return defaultConfig;
  }

  default async command msp430adc12_result_t 
    SingleChannelReadStream.getMultipleData[uint8_t client](
      const msp430adc12_channel_config_t *config,
      uint16_t *buf, uint16_t length, uint16_t jiffies)
  {
    return MSP430ADC12_FAIL_PARAMS;
  }

  default async command msp430adc12_channel_config_t 
    ConfigReadStream.getChannelSettings[uint8_t client]()
  { 
    msp430adc12_channel_config_t defaultConfig = {INPUT_CHANNEL_NONE,0,0,0,0,0,0,0}; 
    return defaultConfig;
  }
}

