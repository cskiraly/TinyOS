#ifndef MSP430ADC12_H
#define MSP430ADC12_H

/*
 * An application using the MSP430ADC12Single or MSP430ADC12Multiple interface 
 * needs to call bind() to bind the interface instance to certain settings which 
 * will be used for all subsequent conversions. In the following a macro,
 * ADC12_SETTINGS(), is provided to conveniently create the parameter for bind.
 * The macro takes 8 arguments:
 * 
 * ADC12_SETTINGS(IC, RV, SHT, CS_SHT, CD_SHT, CS_SAMPCON, CD_SAMPCON, RVL)
 *   
 * The arguments have the following meaning:
 * 
 * IC: Input channel to be sampled. An (external) input channel maps to one of
 * msp430's pins (see device specific data sheet which pin it is mapped to, A0-A7).
 * Make sure this pin is set to module function and input when sampling the
 * channel. Use inputChannel_enum in MSP430ADC12.h for IC.
 * 
 * RV: Reference voltage for the conversion(s). The MSP430 allows conversions with
 * VREF+ as a stable reference voltage (see RefVolt component). Therefore the
 * HAL module checks each request for the reference voltage and if necessary
 * switches on VREF+ automatically (via RefVolt component).  However, because there
 * is a startup delay of max. 17ms for the reference voltage generator to become
 * stable, a call getData() might result in an event dataReady() delayed by 17ms.
 * To avoid this, the application can start the reference voltage generator itself
 * by calling RefVolt.get() 17ms prior to the first conversion (and call
 * RefVolt.release() after the last conversion). Use referenceVoltage_enum in
 * MSP430ADC12.h for RV.
 * 
 * SHT: Sample-hold-time. This defines the time a channel is actually sampled for.  It
 * is measured in clock cycles of the sample-hold clock source (CS_SHT) and depends
 * on the external source resistance, see section ADC12, subsection "Sample Timing
 * Considerations" in msp430 User Guide. Use sampleHold_enum for SHT.
 *      
 * CS_SHT: Clock source for sample-hold-time. Use clockSourceSHT_enum for CS_SHT.
 * 
 * CD_SHT: Clock divider for clock source of sample-hold-time. Use
 * clockDivSHT_enum for CD_SHT.
 *
 * CS_SAMPCON: Clock source for the SAMPCON signal.
 * One characteristic of the MSP430 ADC12 is the ability to define the time 
 * interval between subsequent conversions and let multiple conversions
 * be performed completely in hardware. This is reflected by an additional 
 * parameter (jiffies) in the relevant commands of the HAL interfaces.
 * CS_SAMPCON defines the clock source for and jiffies defines the
 * period in cycles of CS_SAMPCON (see example below). Use
 * clockSourceSAMPCON_enum for CS_SAMPCON.
 *             
 * CD_SAMPCON: Clock divider for clock source of SAMPCON signal.  Together with
 * CS_SAMPCON and the *jiffies* parameter in a getData() command the CD_SAMPCON
 * defines the period a channel is sampled. Use clockSourceSAMPCON_enum for
 * CS_SAMPCON.
 * 
 * RVL: Reference voltage level. This is only valid it for RV either
 * REFERENCE_VREFplus_AVss or REFERENCE_VREFplus_VREFnegterm was chosen, otherwise
 * it is ignored. It specifies the level of VREF+. Use refVolt2_5_enum for RVL.
 * 
 * EXAMPLE:
 * Binding to settings for a sensor on channel A1, using 
 * reference voltage VR+ = VREF+ and VR­ = AVSS, a sample hold-time
 * of 4 * (1/5000000) * 2 = 1.6us, a sampcon source of SMCLK and
 * reference voltage generator level of 1.5 Volt:
 *
 * call MSP430ADC12Multiple.bind(ADC12_SETTINGS(INPUT_CHANNEL_A1, 
 *                                              REFERENCE_VREFplus_AVss,
 *                                              SAMPLE_HOLD_4_CYCLES,
 *                                              SHT_SOURCE_ADC12OSC,
 *                                              SHT_CLOCK_DIV_2,
 *                                              SAMPCON_SOURCE_SMCLK,
 *                                              SAMPCON_CLOCK_DIV_1,
 *                                              REFVOLT_LEVEL_1_5));
 * 
 * Now the following command takes 100 samples, each separated by 1ms 
 * (assuming SMCLK runs at 1MHz):
 *
 * call MSP430ADC12Multiple.getData(buf, 100, 1000);
 *
 * After 17ms (initial start of reference voltage generator) + 100 * 1 ms
 * = 117 ms the corresponding event is signalled.
 * Note that the SAMPCON signal is concurrent to the sampling process,
 * i.e. sample-hold-time is not relevant for the calculation of the 117ms.
 *
 * In the configuration the MSP430ADC12Single and MSP430ADC12Multiple
 * need to be instantiated with unique("MSP430ADC12").
 */
#define ADC12_SETTINGS(IC, RV, SHT, CS_SHT, CD_SHT, CS_SAMPCON, CD_SAMPCON, RVL) \
        (int2adcSettings(((((((((((((((((uint32_t) SHT) << 4) + IC) << 3) \
        + CD_SHT) << 3) + RV) << 2) + CD_SAMPCON) << 2) + CS_SAMPCON) << 2) \
        + CS_SHT) << 1) + RVL)))

/*
 * Defining the 'adcPort' variable in
 * ADCControl.bindPort(uint8_t port, uint8_t adcPort).
 *
 * IC:  member of inputChannel_enum
 * RV:  member of referenceVoltage_enum
 * RVL: member of refVolt2_5_enum
 */
#define ASSOCIATE_ADC_CHANNEL(IC, RV, RVL) \
        ((((RVL << 3) + RV) << 4) + IC)
        
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
} MSP430ADC12Settings_t;
 
typedef enum
{
   MSP430ADC12_FAIL = 0,
   MSP430ADC12_SUCCESS = 1,
   MSP430ADC12_DELAYED = 2,
} msp430ADCresult_t;

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



                             /* private */


typedef union {
   uint32_t i;
   MSP430ADC12Settings_t s;
} MSP430ADC12Settings_ut;


inline MSP430ADC12Settings_t int2adcSettings(uint32_t i){
  MSP430ADC12Settings_ut u;
  u.i = i;
  return u.s;
}

enum
{
  ADC_IDLE = 0,
  SINGLE_CHANNEL = 1,
  REPEAT_SINGLE_CHANNEL = 2,
  SEQUENCE_OF_CHANNELS = 4,
  REPEAT_SEQUENCE_OF_CHANNELS = 8,
  TIMER_USED = 16,
  RESERVED = 32,
  VREF_WAIT = 64,
};
  
/* Test for GCC bug (bitfield access) - only version 3.2.3 is known to be stable */
#define GCC_VERSION (__GNUC__ * 100 + __GNUC_MINOR__ * 10 + __GNUC_PATCHLEVEL__)
#if GCC_VERSION == 332
#error "Your gcc version (3.3.2) contains a bug which results in false accessing \
of bitfields in structs and makes MSP430ADC12M.nc fail ! Install version 3.2.3 instead."
#elif GCC_VERSION != 323
#warning "This version of gcc might contain a bug which results in false accessing \
of bitfields in structs (MSP430ADC12M.nc would fail). Version 3.2.3 is known to be safe."
#endif  

#define ADC12CTL0_DEFAULT 0x0000
#define ADC12CTL0_TIMER_TRIGGERED ((ADC12CTL0_DEFAULT | ADC12ON) & ~(MSC))
#define ADC12CTL0_AUTO_TRIGGERED ((ADC12CTL0_DEFAULT | ADC12ON) | MSC)


typedef struct 
{
  volatile unsigned
  inch: 4,                                     // input channel
  sref: 3,                                     // reference voltage
  eos: 1;                                      // end of sequence flag
} __attribute__ ((packed)) adc12memctl_t;

typedef struct 
{
  unsigned int refVolt2_5: 1;
  unsigned int gotRefVolt: 1;
  unsigned int result_16bit: 1;
  unsigned int clockSourceSHT: 2;
  unsigned int clockSourceSAMPCON: 2;
  unsigned int clockDivSAMPCON: 2;  
  unsigned int clockDivSHT: 3;            
  unsigned int sampleHoldTime: 4; 
  adc12memctl_t memctl;
} __attribute__ ((packed)) adc12settings_t;


#endif
