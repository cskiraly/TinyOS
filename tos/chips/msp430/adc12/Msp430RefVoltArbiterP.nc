/*
 * Copyright (c) 2004, Technische Universität Berlin
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
 * - Neither the name of the Technische Universität Berlin nor the names 
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
 * $Date: 2006-03-08 02:01:47 $
 * @author: Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */

module Msp430RefVoltArbiterP
{
  provides interface Resource as ClientResource[uint8_t client];
  uses {
    interface Resource as AdcResource[uint8_t client];
    interface SplitControl as RefVolt_1_5V;
    interface SplitControl as RefVolt_2_5V;  
    interface Msp430Adc12Config as Config[uint8_t client];
  }
} implementation {
  enum {
    NO_OWNER = 0xFF,
  };
  norace uint8_t owner = NO_OWNER;

  task void switchOff();
  
  async command error_t ClientResource.request[uint8_t client]()
  {
    return call AdcResource.request[client]();
  }
   
  async command error_t ClientResource.immediateRequest[uint8_t client]()
  {
    msp430adc12_channel_config_t settings = call Config.getChannelSettings[client]();
    if (settings.sref == REFERENCE_VREFplus_AVss ||
        settings.sref == REFERENCE_VREFplus_VREFnegterm)
      // always fails, because of the possible start-up delay (and async-sync transition)
      return FAIL;
    else {
      error_t request = call AdcResource.immediateRequest[client]();
      if (request == SUCCESS)
        owner = client;
      return request;
    }
  }

  event void AdcResource.granted[uint8_t client]()
  {
    msp430adc12_channel_config_t settings = call Config.getChannelSettings[client]();
    owner = client;
    if (settings.sref == REFERENCE_VREFplus_AVss ||
        settings.sref == REFERENCE_VREFplus_VREFnegterm){
      error_t started;
      if (settings.ref2_5v == REFVOLT_LEVEL_1_5)
        started = call RefVolt_1_5V.start();
      else
        started = call RefVolt_2_5V.start();
      if (started != SUCCESS){
        owner = NO_OWNER;
        call AdcResource.release[client]();
        call AdcResource.request[client]();
      }
    } else 
      signal ClientResource.granted[client]();
  }
   
  event void RefVolt_1_5V.startDone(error_t error)
  {
    if (owner != NO_OWNER){
      // Note that it can still not be guaranteed that ClientResource.granted()
      // is not signalled after ClientResource.release() has been called.
      signal ClientResource.granted[owner]();
    }
  }
   
  event void RefVolt_2_5V.startDone(error_t error)
  {
    if (owner != NO_OWNER){
      // Note that it can still not be guaranteed that ClientResource.granted()
      // is not signalled after ClientResource.release() has been called.
      signal ClientResource.granted[owner]();
    }
  }

  async command void ClientResource.release[uint8_t client]()
  {
    atomic {
      if (owner == client){
        owner = NO_OWNER;
        post switchOff();
      }
    }
    call AdcResource.release[client]();
  }

  task void switchOff()
  {
    if (owner == NO_OWNER)
      if (call RefVolt_1_5V.stop() != SUCCESS)
        post switchOff();
  }

  event void RefVolt_1_5V.stopDone(error_t error)
  {
  }
  
  event void RefVolt_2_5V.stopDone(error_t error)
  {
  }

  async command uint8_t ClientResource.isOwner()
  {
    return call AdcResource.isOwner();
  }

  default event void ClientResource.granted[uint8_t client](){}
  default async command error_t AdcResource.request[uint8_t client]()
  {
    return FAIL;
  }
  default async command void AdcResource.release[uint8_t client](){}
  default async command msp430adc12_channel_config_t 
    Config.getChannelSettings[uint8_t client]()
  { 
    msp430adc12_channel_config_t defaultConfig = {INPUT_CHANNEL_NONE,0,0,0,0,0,0,0}; 
    return defaultConfig;
  }
}  

