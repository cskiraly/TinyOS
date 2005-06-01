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
 * $Date: 2005-06-01 03:17:37 $
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
   MSP430ADC12_DELAYED,            // conversion will start when VREF high (max 17ms)
   MSP430ADC12_FAIL_NOT_RESERVED,  // error: client has not reserved (request failed)
   MSP430ADC12_FAIL_VREF,          // VREF in use at different voltage level (request failed)
   MSP430ADC12_FAIL_JIFFIES,       // jiffies out of bounds (request failed)
   MSP430ADC12_FAIL_LENGTH,        // length value illegal (request failed)
   MSP430ADC12_FAIL_BUSY,          // request already pending for client (second request failed)
} msp430adc12_result_t;

typedef struct 
{
  unsigned int refVolt2_5: 1;         // reference voltage level
  unsigned int clockSourceSHT: 2;     // clock source sample-hold-time
  unsigned int clockSourceSAMPCON: 2; // clock source sampcon signal
  unsigned int clockDivSAMPCON: 2;    // clock divider sampcon
  unsigned int referenceVoltage: 3;   // reference voltage
  unsigned int clockDivSHT: 3;        // clock divider sample-hold-time
  unsigned int inputChannel: 4;       // input channel
  unsigned int sampleHoldTime: 4;     // sample-hold-time
  unsigned int : 0;                   // aligned to a word boundary 
} msp430adc12_channel_config_t;

/*
 * When the MSP430ADC12SingleChannel.getConfigurationData() event is 
 * signalled an application must return the settings for the channel
 * it wants to sample as a msp430adc12_channel_config_t. 
 * For convenience a macro, ADC12_SETTINGS, is provided below that
 * allows a msp430adc12_channel_config_t to be displayed as a
 * constant (e.g. to be placed in hardware.h or sensorboard file):
 * The macro takes 8 arguments:
 * ADC12_SETTINGS(IC, RV, SHT, CS_SHT, CD_SHT, CS_SAMPCON, CD_SAMPCON, RVL)
 *   
 * IC: Input channel to be sampled. An (external) input channel maps
 *     to one of msp430's pins (see device specific data sheet which pin
 *     it is mapped to, A0-A7).  The HAL1 will take care of configuring
 *     the corresponding pin automatically (set it to module function and
 *     input). Use inputChannel_enum (below) for IC.
 * 
 * RV: Reference voltage for the conversion(s). The MSP430 allows
 *     conversions with VREF+ as a stable reference voltage (see
 *     RefVoltGenerator component). Therefore the HAL1 module checks each
 *     request for the reference voltage and if necessary switches on
 *     VREF+ automatically (via RefVoltGenerator component).  Because
 *     there is a startup delay of 17ms for the reference voltage
 *     generator to become stable, a call getData() might result in an
 *     event dataReady() delayed by 17ms.  To avoid this, the application
 *     can start the reference voltage generator itself (via
 *     RefVoltGenerator component) 17ms prior to the first conversion.
 *     Use referenceVoltage_enum (below) for RV.
 * 
 * SHT: Sample-hold-time. This defines the time a channel is actually
 *     sampled for.  It is measured in clock cycles of the sample-hold
 *     clock source (CS_SHT) and depends on the external source
 *     resistance, see section ADC12, subsection "Sample Timing
 *     Considerations" in msp430 User Guide. Use sampleHold_enum for SHT.
 *      
 * CS_SHT: Clock source for sample-hold-time. Use clockSourceSHT_enum
 *     for CS_SHT.
 * 
 * CD_SHT: Clock divider for clock source of sample-hold-time. Use
 *     clockDivSHT_enum for CD_SHT.
 *
 * CS_SAMPCON: Clock source for the SAMPCON signal.  One
 *     characteristic of the MSP430 ADC12 is the ability to define the
 *     time interval between subsequent conversions and let multiple
 *     conversions be performed completely in hardware. This is reflected
 *     by an additional parameter (jiffies) in the relevant commands of
 *     the HAL interfaces.  CS_SAMPCON defines the clock source for and
 *     jiffies defines the period in cycles of CS_SAMPCON (see example
 *     below). Use clockSourceSAMPCON_enum for CS_SAMPCON.
 *                 
 * CD_SAMPCON: Clock divider for clock source of SAMPCON signal.
 *     Together with CS_SAMPCON and the *jiffies* parameter in a getData()
 *     command the CD_SAMPCON defines the period a channel is sampled. Use
 *     clockSourceSAMPCON_enum for CS_SAMPCON.
 * 
 * RVL: Reference voltage level. This is only valid it for RV either
 *     REFERENCE_VREFplus_AVss or REFERENCE_VREFplus_VREFnegterm was
 *     chosen, otherwise it is ignored. It specifies the level of VREF+.
 *     Use refVolt2_5_enum for RVL.
 * 
 * EXAMPLE:
 * Settings for a sensor on channel A1, using 
 * reference voltage VR+ = VREF+ and VR­ = AVSS, a sample hold-time
 * of 4 * (1/5000000) * 2 = 1.6us, a sampcon source of SMCLK and
 * reference voltage level of 1.5 Volt:
 *
 * // in hardware.h:
 * #define CHANNEL_A1_SETTINGS ADC12_SETTINGS(INPUT_CHANNEL_A1, \
 *                                              REFERENCE_VREFplus_AVss, \
 *                                              SAMPLE_HOLD_4_CYCLES, \
 *                                              SHT_SOURCE_ADC12OSC, \
 *                                              SHT_CLOCK_DIV_2, \
 *                                              SAMPCON_SOURCE_SMCLK, \
 *                                              SAMPCON_CLOCK_DIV_1, \
 *                                              REFVOLT_LEVEL_1_5))
 *  
 * // in application
 * async event msp430adc12_channel_config_t MSP430ADC12SingleChannel.getConfigurationData()
 * {
 *   return CHANNEL_A1_SETTINGS;
 * }
 * 
 * The following command now takes 100 samples, each separated by a
 * 1ms delay (assuming SMCLK runs at 1MHz):
 *
 * call MSP430ADC12SingleChannel.getMultipleData(buf, 100, 1000);
 *
 * After 17ms (initial start of reference voltage generator) + 100 *
 * 1000 us = 117 ms the multipleDataReady() event is signalled.  Note
 * that the SAMPCON signal is concurrent to the sampling process, i.e.
 * sample-hold-time is not relevant for the calculation of the 117ms.
 */
#define ADC12_SETTINGS(IC, RV, SHT, CS_SHT, CD_SHT, CS_SAMPCON, CD_SAMPCON, RVL) \
        (int2adcSettings(((((((((((((((((uint32_t) SHT) << 4) + IC) << 3) \
        + CD_SHT) << 3) + RV) << 2) + CD_SAMPCON) << 2) + CS_SAMPCON) << 2) \
        + CS_SHT) << 1) + RVL)))

 

enum refVolt2_5_enum
{
  REFVOLT_LEVEL_1_5 = 0,                    // reference voltage of 1.5 V
  REFVOLT_LEVEL_2_5 = 1,                    // reference voltage of 2.5 V
};

enum clockDivSHT_enum
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

enum clockDivSAMPCON_enum
{
   SAMPCON_CLOCK_DIV_1 = 0,             // SAMPCON clock divider of 1
   SAMPCON_CLOCK_DIV_2 = 1,             // SAMPCON clock divider of 2
   SAMPCON_CLOCK_DIV_3 = 2,             // SAMPCON clock divider of 3
   SAMPCON_CLOCK_DIV_4 = 3,             // SAMPCON clock divider of 4
};

enum clockSourceSAMPCON_enum
{
   SAMPCON_SOURCE_TACLK = 0,        // Timer A clock source is (external) TACLK
   SAMPCON_SOURCE_ACLK = 1,         // Timer A clock source ACLK
   SAMPCON_SOURCE_SMCLK = 2,        // Timer A clock source SMCLK
   SAMPCON_SOURCE_INCLK = 3,        // Timer A clock source is (external) INCLK
};

enum inputChannel_enum
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

enum referenceVoltage_enum
{
   REFERENCE_AVcc_AVss = 0,                 // VR+ = AVcc   and VR-= AVss
   REFERENCE_VREFplus_AVss = 1,             // VR+ = VREF+  and VR-= AVss
   REFERENCE_VeREFplus_AVss = 2,            // VR+ = VeREF+ and VR-= AVss
   REFERENCE_AVcc_VREFnegterm = 4,          // VR+ = AVcc   and VR-= VREF-/VeREF- 
   REFERENCE_VREFplus_VREFnegterm = 5,      // VR+ = VREF+  and VR-= VREF-/VeREF-   
   REFERENCE_VeREFplus_VREFnegterm = 6      // VR+ = VeREF+ and VR-= VREF-/VeREF-
};

enum clockSourceSHT_enum
{
   SHT_SOURCE_ADC12OSC = 0,                // ADC12OSC
   SHT_SOURCE_ACLK = 1,                    // ACLK
   SHT_SOURCE_MCLK = 2,                    // MCLK
   SHT_SOURCE_SMCLK = 3                    // SMCLK
};

enum sampleHold_enum
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


//////////////////////////////////////////////////////////////////

typedef union {
   uint32_t i;
   msp430adc12_channel_config_t s;
} msp430adc12_channel_config_ut;

 msp430adc12_channel_config_t int2adcSettings(uint32_t i){
  msp430adc12_channel_config_ut u;
  u.i = i;
  return u.s;
}

// Wrappers wiring to HAL1 must do so via MSP430ADC12Client, which
// uses the same interface ID for the Resource and 
// MSP430ADC12SingleChannel interfaces, because HAL1 checks each 
// request from MSP430ADC12SingleChannel for matching reservation. 
// In order not to mess up the ADCC reservations the MSP430ADC12Client
// wires to Resource interface instances starting with the ID defined
// below. Thus the ADCC may use Resource ID 0 to 
// ADC_RESOURCE_RESERVED_BY_ADCC-1 and MSP430ADC12Client may use use IDs
// ADC_RESOURCE_RESERVED_BY_ADCC to 255 of HAL1. Note that this is
// transparent from wrapper/application. 
#define ADC_RESOURCE_RESERVED_BY_ADCC 128

/* Test for GCC bug (bitfield access) - only version 3.2.3 is known to be stable */
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
