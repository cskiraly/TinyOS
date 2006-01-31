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
 * $Revision: 1.1.2.4 $
 * $Date: 2006-01-31 18:53:36 $
 * @author: Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */

/**
 * Default ADC channel configuration for eyesIFXv1 and eyesIFXv2. Future
 * eyesIFX platforms may shadow this configuration (and sensors.h) in their
 * respective subdirectory.
 *
 * @author Jan Hauer
 */

#include <sensors.h>
module SensorSettingsC {
  provides interface Msp430Adc12Config[uint8_t type];  
}
implementation
{
  async command msp430adc12_channel_config_t Msp430Adc12Config.getChannelSettings[uint8_t type]()
  {
    msp430adc12_channel_config_t defaultSettings = {INPUT_CHANNEL_NONE,0,0,0,0,0,0,0};
    switch (type)
    {
      case PHOTO_SENSOR_LOW_FREQ:
        {
          msp430adc12_channel_config_t config = {
                      INPUT_CHANNEL_A2, REFERENCE_VREFplus_AVss, REFVOLT_LEVEL_1_5,
                      SHT_SOURCE_ACLK, SHT_CLOCK_DIV_1, SAMPLE_HOLD_4_CYCLES,
                      SAMPCON_SOURCE_ACLK, SAMPCON_CLOCK_DIV_1 };
          return config;
        }
      case PHOTO_SENSOR_DEFAULT: // fall through
      case PHOTO_SENSOR_HIGH_FREQ:
        {
          msp430adc12_channel_config_t config = {
                      INPUT_CHANNEL_A2, REFERENCE_VREFplus_AVss, REFVOLT_LEVEL_1_5,
                      SHT_SOURCE_SMCLK, SHT_CLOCK_DIV_1, SAMPLE_HOLD_4_CYCLES,
                      SAMPCON_SOURCE_SMCLK, SAMPCON_CLOCK_DIV_1 };
          return config;
        }
      case PHOTO_SENSOR_VCC:
        {
          msp430adc12_channel_config_t config = {
                      INPUT_CHANNEL_A2, REFERENCE_AVcc_AVss, REFVOLT_LEVEL_NONE,
                      SHT_SOURCE_SMCLK, SHT_CLOCK_DIV_1, SAMPLE_HOLD_4_CYCLES,
                      SAMPCON_SOURCE_SMCLK, SAMPCON_CLOCK_DIV_1 };
          return config;
        }        
      case TEMP_SENSOR_LOW_FREQ:
        {
          msp430adc12_channel_config_t config = {
                      INPUT_CHANNEL_A0, REFERENCE_VREFplus_AVss, REFVOLT_LEVEL_1_5,
                      SHT_SOURCE_ACLK, SHT_CLOCK_DIV_1, SAMPLE_HOLD_4_CYCLES,
                      SAMPCON_SOURCE_ACLK, SAMPCON_CLOCK_DIV_1 };
          return config;
        }
      case TEMP_SENSOR_HIGH_FREQ: // fall through
      case TEMP_SENSOR_DEFAULT:
        {
          msp430adc12_channel_config_t config = {
                      INPUT_CHANNEL_A0, REFERENCE_VREFplus_AVss, REFVOLT_LEVEL_1_5,
                      SHT_SOURCE_SMCLK, SHT_CLOCK_DIV_1, SAMPLE_HOLD_4_CYCLES,
                      SAMPCON_SOURCE_SMCLK, SAMPCON_CLOCK_DIV_1 };
          return config;
        }
      case RSSI_SENSOR_DEFAULT: // fall through
      case RSSI_SENSOR_VCC:
        {
          msp430adc12_channel_config_t config = {
                      INPUT_CHANNEL_A3, REFERENCE_AVcc_AVss, REFVOLT_LEVEL_NONE,
                      SHT_SOURCE_SMCLK, SHT_CLOCK_DIV_1, SAMPLE_HOLD_4_CYCLES,
                      SAMPCON_SOURCE_SMCLK, SAMPCON_CLOCK_DIV_1 };
          return config;
        }
      case RSSI_SENSOR_REF_1_5V:
        {
          msp430adc12_channel_config_t config = {
                      INPUT_CHANNEL_A3, REFERENCE_VREFplus_AVss, REFVOLT_LEVEL_1_5,
                      SHT_SOURCE_SMCLK, SHT_CLOCK_DIV_1, SAMPLE_HOLD_4_CYCLES,
                      SAMPCON_SOURCE_SMCLK, SAMPCON_CLOCK_DIV_1 };
          return config;
        }
    }
    return defaultSettings;
  }
}

