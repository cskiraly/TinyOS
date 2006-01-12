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
 * $Date: 2006-01-12 18:01:46 $
 * @author: Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */
 
#ifndef MSP430ADC12_H
#define MSP430ADC12_H
#include "Msp430RefVoltGenerator.h"

#define P6PIN_AUTO_CONFIGURE

typedef enum
{
   MSP430ADC12_SUCCESS,            // conversion started successfully 
   MSP430ADC12_DELAYED,            // conversion will start when VREF stable (max 17ms)
   MSP430ADC12_FAIL_NOT_RESERVED,  // failed: client has not reserved
   MSP430ADC12_FAIL_PARAMS,        // failed: parameters illegal (out of range)
   MSP430ADC12_FAIL_VREF,          // failed: VREF in use at different voltage level
   MSP430ADC12_FAIL_JIFFIES,       // failed: jiffies out of bounds
   MSP430ADC12_FAIL_BUSY,          // failed: request already pending for client
} msp430adc12_result_t;


/**
  The msp430adc12_channel_config_t struct encapsulates the relevant flags for
  ADC configuration on a per-client basis from ADC12CTL0, ADC12CTL1,
  ADC12MCTLx and TACTL of TimerA (if applicable). The members of
  msp430adc12_channel_config_t are as follows (see also section "17.3 ADC12
  Registers" of the "MSP430x1xx Family User's Guide",
  http://focus.ti.com/lit/ug/slau049e/slau049e.pdf):
 
                    **********************************

  inch (ADC12MCTLx): ADC input channel. An (external) input channel maps to
  one of msp430's A0-A7 pins (see device specific data sheet).
 
  sref (ADC12MCTLx): Reference voltage. If REFERENCE_VREFplus_AVss or
  REFERENCE_VREFplus_VREFnegterm is chosen then the voltage level of VREF is
  defined by the "ref2_5v" flag.
  
  ref2_5v (ADC12CTL0): Reference generator voltage. This flag is only relevant
  if "sref" is either REFERENCE_VREFplus_AVss REFERENCE_VREFplus_VREFnegterm,
  it is ignored otherwise.  It defines the voltage level of the reference
  generator, during the sampling process. The ADC HAL1 automatically switches
  the reference generator to the level specified in "ref2_5v" for the sampling
  process.  Because the switch-on time may result in a 17 ms delay (depending
  on whether VREF is stable), a getData() call may be delayed
  (MSP430ADC12_DELAYED is returned).  To avoid this delay, the application may
  start the reference voltage generator itself 17 ms prior to the first
  conversion to be stable at the time getData() is called.
 
  adc12ssel (ADC12CTL1): ADC12 clock source select for sample-hold-time. In
  combination with  "adc12ssel", "adc12div" and "sht" it defines the
  sample-hold-time. The sample-hold-time depends on the device (sensor)
  characteristics, use the formula in section "17.2.4 Sample Timing
  Considerations" of the User's Guide. 
 
  adc12div (ADC12CTL1): ADC12 clock divider. See "adc12ssel" flag.
 
  sht (ADC12CTL0): Sample-and-hold time. Defines the number of clock cycles in
  the sampling period (clock source defined by "adc12ssel", input divider
  defined by "adc12div").
 
  sampcon_ssel (no ADC register, but identical to TASSEL in TACTL, TimerA): In
  combination with "sampcon_id" and the "jiffies" parameter the "sampcon_ssel"
  defines the sampling rate. It is the clock source for the SAMPCON signal,
  which triggers the sampling. It is not relevant if only getSingleData() is
  used or the "jiffies" parameter is zero; otherwise the SAMPCON signal is
  sourced from TimerA, so that the multiple conversion mode can be made with a
  user defined sampling rate.
 
  sampcon_id (no ADC register, but identical to IDx in TACTL, TimerA): Input
  divider for "sampcon_ssel".
 
                    **********************************

  EXAMPLE: Assuming that SMCLK runs at 1 MHz the following command fills the
  user buffer with 2000 conversion results sampled on channel A2 with a
  sampling rate of 4000 Hz, i.e. the dataReady() event is signalled after 500
  ms (plus a possible 17 ms delay for the reference voltage generator to
  become stable). Note that the sampling rate is defined by the combination of
  SAMPCON_SOURCE_SMCLK, SAMPCON_CLOCK_DIV_1 and the "jiffies" parameter of 250.

  
  uint16_t buffer[2000];
  msp430adc12_channel_config_t config = {
    INPUT_CHANNEL_A2, REFERENCE_VREFplus_AVss, REFVOLT_LEVEL_1_5,
    SHT_SOURCE_SMCLK, SHT_CLOCK_DIV_1, SAMPLE_HOLD_64_CYCLES,
    SAMPCON_SOURCE_SMCLK, SAMPCON_CLOCK_DIV_1 
  };
  
  event void Resource.granted() 
  { 
    if (call SingleChannel.getMultipleData(&config, buffer, 2000, 250)
        == MSP430ADC12_SUCCESS)
    {
      // .. go on in multipleDataReady() event
    } else {
      // check error
    } 
  }
 */
typedef struct { 
  unsigned int inch: 4;            // input channel 
  unsigned int sref: 3;            // reference voltage 
  unsigned int ref2_5v: 1;         // reference voltage level 
  unsigned int adc12ssel: 2;       // clock source sample-hold-time 
  unsigned int adc12div: 3;        // clock divider sample-hold-time 
  unsigned int sht: 4;             // sample-hold-time
  unsigned int sampcon_ssel: 2;    // clock source sampcon signal 
  unsigned int sampcon_id: 2;      // clock divider sampcon 
  unsigned int : 0;                // align to a word boundary 
} msp430adc12_channel_config_t;

enum inch_enum
{  
   // see device specific data sheet which pin Ax is mapped to
   INPUT_CHANNEL_A0 = 0,                    // input channel A0 
   INPUT_CHANNEL_A1 = 1,                    // input channel A1
   INPUT_CHANNEL_A2 = 2,                    // input channel A2
   INPUT_CHANNEL_A3 = 3,                    // input channel A3
   INPUT_CHANNEL_A4 = 4,                    // input channel A4
   INPUT_CHANNEL_A5 = 5,                    // input channel A5
   INPUT_CHANNEL_A6 = 6,                    // input channel A6
   INPUT_CHANNEL_A7 = 7,                    // input channel A7
   EXTERNAL_REFERENCE_VOLTAGE = 8,          // VeREF+ (input channel 8)
   REFERENCE_VOLTAGE_NEGATIVE_TERMINAL = 9, // VREF-/VeREF- (input channel 9)
   INTERNAL_TEMPERATURE = 10,               // Temperature diode (input channel 10)
   INTERNAL_VOLTAGE = 11,                   // (AVcc-AVss)/2 (input channel 11-15)
   INPUT_CHANNEL_NONE = 12                  // illegal (identifies invalid settings)
};

enum sref_enum
{
   REFERENCE_AVcc_AVss = 0,                 // VR+ = AVcc   and VR-= AVss
   REFERENCE_VREFplus_AVss = 1,             // VR+ = VREF+  and VR-= AVss
   REFERENCE_VeREFplus_AVss = 2,            // VR+ = VeREF+ and VR-= AVss
   REFERENCE_AVcc_VREFnegterm = 4,          // VR+ = AVcc   and VR-= VREF-/VeREF- 
   REFERENCE_VREFplus_VREFnegterm = 5,      // VR+ = VREF+  and VR-= VREF-/VeREF-   
   REFERENCE_VeREFplus_VREFnegterm = 6      // VR+ = VeREF+ and VR-= VREF-/VeREF-
};

enum ref2_5v_enum
{
  REFVOLT_LEVEL_1_5 = 0,                    // reference voltage of 1.5 V
  REFVOLT_LEVEL_2_5 = 1,                    // reference voltage of 2.5 V
  REFVOLT_LEVEL_NONE = 0,                   // if e.g. AVcc is chosen 
};

enum adc12ssel_enum
{
   SHT_SOURCE_ADC12OSC = 0,                // ADC12OSC
   SHT_SOURCE_ACLK = 1,                    // ACLK
   SHT_SOURCE_MCLK = 2,                    // MCLK
   SHT_SOURCE_SMCLK = 3                    // SMCLK
};

enum adc12div_enum
{
   SHT_CLOCK_DIV_1 = 0,                         // ADC12 clock divider of 1
   SHT_CLOCK_DIV_2 = 1,                         // ADC12 clock divider of 2
   SHT_CLOCK_DIV_3 = 2,                         // ADC12 clock divider of 3
   SHT_CLOCK_DIV_4 = 3,                         // ADC12 clock divider of 4
   SHT_CLOCK_DIV_5 = 4,                         // ADC12 clock divider of 5
   SHT_CLOCK_DIV_6 = 5,                         // ADC12 clock divider of 6
   SHT_CLOCK_DIV_7 = 6,                         // ADC12 clock divider of 7
   SHT_CLOCK_DIV_8 = 7,                         // ADC12 clock divider of 8
};

enum sht_enum
{
   SAMPLE_HOLD_4_CYCLES = 0,         // sampling duration is 4 clock cycles
   SAMPLE_HOLD_8_CYCLES = 1,         // ...
   SAMPLE_HOLD_16_CYCLES = 2,         
   SAMPLE_HOLD_32_CYCLES = 3,         
   SAMPLE_HOLD_64_CYCLES = 4,         
   SAMPLE_HOLD_96_CYCLES = 5,        
   SAMPLE_HOLD_123_CYCLES = 6,        
   SAMPLE_HOLD_192_CYCLES = 7,        
   SAMPLE_HOLD_256_CYCLES = 8,        
   SAMPLE_HOLD_384_CYCLES = 9,        
   SAMPLE_HOLD_512_CYCLES = 10,        
   SAMPLE_HOLD_768_CYCLES = 11,        
   SAMPLE_HOLD_1024_CYCLES = 12       
};

enum sampcon_ssel_enum
{
   SAMPCON_SOURCE_TACLK = 0,        // Timer A clock source is (external) TACLK
   SAMPCON_SOURCE_ACLK = 1,         // Timer A clock source ACLK
   SAMPCON_SOURCE_SMCLK = 2,        // Timer A clock source SMCLK
   SAMPCON_SOURCE_INCLK = 3,        // Timer A clock source is (external) INCLK
};

enum sampcon_id_enum
{
   SAMPCON_CLOCK_DIV_1 = 0,             // SAMPCON clock divider of 1
   SAMPCON_CLOCK_DIV_2 = 1,             // SAMPCON clock divider of 2
   SAMPCON_CLOCK_DIV_3 = 2,             // SAMPCON clock divider of 3
   SAMPCON_CLOCK_DIV_4 = 3,             // SAMPCON clock divider of 4
};

// The unique string for allocating ADC resource interfaces
#define MSP430ADC12_RESOURCE "Msp430Adc12C.Resource"

// The unique string for accessing HAL2
#define ADCC_SERVICE "AdcC.Service"

typedef struct 
{
  volatile unsigned
  inch: 4,                                     // input channel
  sref: 3,                                     // reference voltage
  eos: 1;                                      // end of sequence flag
} __attribute__ ((packed)) adc12memctl_t;

/* Test for GCC bug (bitfield access) - only version 3.2.3 is known to be stable */
// check: is this relevant anymore ?
#define GCC_VERSION (__GNUC__ * 100 + __GNUC_MINOR__ * 10 + __GNUC_PATCHLEVEL__)
#if GCC_VERSION == 332
#error "The msp430-gcc version (3.3.2) contains a bug which results in false accessing \
of bitfields in structs and makes MSP430ADC12M.nc fail ! Use version 3.2.3 instead."
#elif GCC_VERSION != 323
#warning "This version of msp430-gcc might contain a bug which results in false accessing \
of bitfields in structs (MSP430ADC12M.nc would fail). Use version 3.2.3 instead."
#endif  

#endif
