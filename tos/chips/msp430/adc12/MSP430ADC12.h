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
 * $Revision: 1.1.2.5 $
 * $Date: 2005-06-04 00:03:57 $
 * @author: Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */
 
#ifndef MSP430ADC12_H
#define MSP430ADC12_H
#include "RefVoltGenerator.h"
#include "ADC.h"

typedef enum
{
   MSP430ADC12_SUCCESS,            // conversion started successfully 
   MSP430ADC12_DELAYED,            // conversion will start when VREF stable (max 17ms)
   MSP430ADC12_FAIL_NOT_RESERVED,  // error: client has not reserved (request failed)
   MSP430ADC12_FAIL_VREF,          // VREF in use at different voltage level (request failed)
   MSP430ADC12_FAIL_JIFFIES,       // jiffies out of bounds (request failed)
   MSP430ADC12_FAIL_LENGTH,        // length value illegal (request failed)
   MSP430ADC12_FAIL_BUSY,          // request already pending for client (request failed)
} msp430adc12_result_t;


/*
 * When the MSP430ADC12SingleChannel.getConfigurationData() event is
 * signalled the client component must return the configuration
 * settings (msp430adc12_channel_config_t) for the channel it wants to
 * sample.  These configuration settings are used by the HAL1
 * component to set the relevant flags in the ADC12CTL0, ADC12CTL1 and
 * ADC12MCTLx (and possibly TACTL of TimerA) registers prior to
 * starting the actual sampling process. The
 * msp430adc12_channel_config_t struct incorporates 8 members, their
 * naming and meaning is also described in the section "17.3 ADC12
 * Registers" of the "MSP430x1xx Family User's Guide"
 * (http://focus.ti.com/lit/ug/slau049e/slau049e.pdf). The struct
 * members in detail:
 *
 ******************************************************************************
 *
 * inch (ADC12MCTLx):
 *    ADC input channel. An (external) input channel maps
 *    to one of msp430's A0-A7 pins (see device specific data sheet).
 *
 * sref (ADC12MCTLx): 
 *    Reference voltage. If 1 (REFERENCE_VREFplus_AVss) or 5
 *    (REFERENCE_VREFplus_VREFnegterm) is chosen then the voltage
 *    level of VREF is defined by the "ref2_5v" flag.
 * 
 * ref2_5v (ADC12CTL0): 
 *     Reference generator voltage. This flag is only relevant if for
 *     "sref" either 1 (REFERENCE_VREFplus_AVss) or 5
 *     (REFERENCE_VREFplus_VREFnegterm) was chosen, it is ignored
 *     otherwise.  It defines the voltage level of the reference
 *     generator, during the sampling process. The ADC HAL1
 *     automatically switches on the reference generator to the level
 *     specified in "ref2_5v" for the sampling process.  Because the
 *     switch-on time may result in a 17ms delay (depending on
 *     whether VREF is stable), a getData() call may be delayed
 *     (MSP430ADC12_DELAYED is returned).  To avoid this delay, the
 *     application may start the reference voltage generator itself
 *     (via RefVoltGenerator component) 17ms prior to the first
 *     conversion to be stable at the time getData() is called.
 *
 * adc12ssel (ADC12CTL1): 
 *     ADC12 clock source select for sample-hold-time. In connection
 *     the "adc12ssel", "adc12div" and "sht" flags define the
 *     sample-hold-time. The sample-hold-time depends on the source
 *     (sensor) characteristics and is to be calculated using the
 *     formula in the section "17.2.4 Sample Timing Considerations"
 *     in the User's Guide.
 *
 * adc12div (ADC12CTL1):
 *     ADC12 clock divider. See "adc12ssel" flag.
 *
 * sht (ADC12CTL0):
 *     Sample-and-hold time. Define the number of clock cycles in the 
 *     sampling period (clock source defined by "adc12ssel", input 
 *     divider defined by "adc12div").
 *
 * sampcon_ssel (no ADC register, but identical to TASSEL in TACTL, TimerA): 
 *     Clock source select for the SAMPCON signal (which is starting
 *     the sampling process). Not relevant if only getSingleData() is
 *     used or the "jiffies" parameter in the other getData()
 *     commands is zero; otherwise the SAMPCON signal is sourced from
 *     TimerA (unchangeable for client app), so that multiple (up to
 *     16) conversions can be done in hardware without generating an
 *     interrupt after every single conversion (this allows
 *     high-frequency sampling).  In connection the "sampcon_ssel"
 *     and "sampcon_id" flags together with the "jiffies" parameter
 *     in the MSP430ADC12SingleChannel commands define the time
 *     interval between subsequent conversions.
 *
 * sampcon_id (no ADC register, but identical to IDx in TACTL, TimerA): 
 *     Input divider for "sampcon_ssel".
 *
 ******************************************************************************
 *
 * EXAMPLE:
 *
 * An application might implement the following eventhandler:
 *
 * async event msp430adc12_channel_config_t MSP430ADC12SingleChannel.getConfigurationData()
 * {
 *   msp430adc12_channel_config_t channelConfig;
 *   channelConfig.inch = INPUT_CHANNEL_A1;
 *   channelConfig.sref = REFERENCE_VREFplus_AVss;
 *   channelConfig.ref2_5v = REFVOLT_LEVEL_1_5;
 *   channelConfig.adc12ssel = SHT_SOURCE_ADC12OSC;
 *   channelConfig.adc12div = SHT_CLOCK_DIV_2;
 *   channelConfig.sht = SAMPLE_HOLD_4_CYCLES;
 *   channelConfig.sampcon_ssel = SAMPCON_SOURCE_SMCLK;
 *   channelConfig.sampcon_id = SAMPCON_CLOCK_DIV_1;
 *   return channelConfig;
 * }
 * 
 * Then the following command takes 100 samples on channel A1, 
 * each separated by a 1ms interval (assuming SMCLK runs at 1MHz):
 *
 * call MSP430ADC12SingleChannel.getMultipleData(buf, 100, 1000);
 *
 * After 17ms (initial start of reference voltage generator) + 100 *
 * 1000 us = 117 ms the multipleDataReady() event is signalled with 100
 * conversion results ready in the buffer "buf".  Note that the SAMPCON 
 * signal is concurrent to the sampling process, i.e.
 * sample-hold-time is not relevant for the calculation of the 117ms.
 */
typedef struct 
{
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
   INTERNAL_VOLTAGE = 11                    // (AVcc-AVss)/2 (input channel 11-15)
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

 /******************************* internal ***********************************/

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

typedef struct 
{
  volatile unsigned
  inch: 4,                                     // input channel
  sref: 3,                                     // reference voltage
  eos: 1;                                      // end of sequence flag
} __attribute__ ((packed)) adc12memctl_t;

#endif
