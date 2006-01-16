/*
 * Copyright (c) 2006, Technische Universitaet Berlin
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
 * $Date: 2006-01-16 16:00:22 $
 * @author: Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */

/* 
 * ADC12 configuration for input channel 10 (Temperature diode) and 11 ((AVCC –
 * AVSS) / 2).
 */
#include <internalchannels.h>
#include <Msp430Adc12.h>
module Msp430Adc12InternalChannelsC {
  provides interface Msp430Adc12Config[uint8_t type];  
}
implementation
{
  async command msp430adc12_channel_config_t Msp430Adc12Config.getChannelSettings[uint8_t type]()
  {
    msp430adc12_channel_config_t defaultSettings = {INPUT_CHANNEL_NONE,0,0,0,0,0,0,0};
    switch (type)
    {
      case ADC12_TEMPERATURE_DIODE:
        {
          msp430adc12_channel_config_t config = {
                      TEMPERATURE_DIODE_CHANNEL, REFERENCE_VREFplus_AVss, REFVOLT_LEVEL_1_5,
                      SHT_SOURCE_ACLK, SHT_CLOCK_DIV_1, SAMPLE_HOLD_4_CYCLES,
                      SAMPCON_SOURCE_ACLK, SAMPCON_CLOCK_DIV_1 };
          return config;
        }
      case ADC12_SUPPLY_VOLTAGE:
        {
          msp430adc12_channel_config_t config = {
                      SUPPLY_VOLTAGE_HALF_CHANNEL, REFERENCE_VREFplus_AVss, REFVOLT_LEVEL_1_5,
                      SHT_SOURCE_ACLK, SHT_CLOCK_DIV_1, SAMPLE_HOLD_4_CYCLES,
                      SAMPCON_SOURCE_ACLK, SAMPCON_CLOCK_DIV_1 };
          return config;
        }
      default:
        break;
    }
    return defaultSettings;
  }
}

