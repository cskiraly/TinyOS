/**
 * "Copyright (c) 2009 The Regents of the University of California.
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement
 * is hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 *
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY
 * OF CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 */

/**
 * Power Management Controller register definitions.
 *
 * @author Thomas Schmid
 */

#ifndef PMCHARDWARE_H
#define PMCHARDWARE_H

/**
 * PMC System Clock Enable Register, AT91 ARM Cortex-M3 based Microcontrollers
 * SAM3U Series, Preliminary, p. 482
 * 0: no effect
 * 1: enable clock
 */
typedef union
{
    uint32_t flat;
    struct
    {
        uint8_t reserved0 : 8;
        uint8_t pck0      : 1; // enables clock output 0
        uint8_t pck1      : 1; // enables clock output 1
        uint8_t pck2      : 1; // enables clock output 2
        uint8_t reserved1 : 5;
        uint16_t reserved2 : 16;
    } __attribute__((__packed__)) bits;
} pmc_scer_t;

/**
 * PMC System Clock Disable Register, AT91 ARM Cortex-M3 based Microcontrollers
 * SAM3U Series, Preliminary, p. 483
 * 0: no effect
 * 1: disable clock
 */
typedef union
{
    uint32_t flat;
    struct
    {
        uint8_t reserved0 : 8;
        uint8_t pck0      : 1; // disables clock output 0
        uint8_t pck1      : 1; // disables clock output 1
        uint8_t pck2      : 1; // disables clock output 2
        uint8_t reserved1 : 5;
        uint16_t reserved2 : 16;
    } __attribute__((__packed__))  bits;
} pmc_scdr_t;

/**
 * PMC System Clock Status Register, AT91 ARM Cortex-M3 based Microcontrollers
 * SAM3U Series, Preliminary, p. 484
 * 0: clock disabled
 * 1: clock enabled
 */
typedef union
{
    uint32_t flat;
    struct
    {
        uint8_t reserved0 : 8;
        uint8_t pck0      : 1; // status of clock output 0
        uint8_t pck1      : 1; // status of clock output 1
        uint8_t pck2      : 1; // status of clock output 2
        uint8_t reserved1 : 5;
        uint16_t reserved2 : 16;
    } __attribute__((__packed__)) bits;
} pmc_scsr_t;

/**
 * PMC Peripheral Clock Enable Register, AT91 ARM Cortex-M3 based Microcontrollers
 * SAM3U Series, Preliminary, p. 485
 * 0: no effect
 * 1: enable corresponding peripheral clock
 */
typedef union
{
    uint32_t flat;
    struct
    {
        uint8_t reserved0 : 2;
        uint8_t rtc       : 1; // not used after datasheet
        uint8_t rtt       : 1; // not used after datasheet
        uint8_t wdg       : 1; // not used after datasheet
        uint8_t pmc       : 1; // not used after datasheet
        uint8_t efc0      : 1; // not used after datasheet
        uint8_t efc1      : 1; // not used after datasheet
        uint8_t dbgu      : 1;
        uint8_t hsmc4     : 1;
        uint8_t pioa      : 1;
        uint8_t piob      : 1;
        uint8_t pioc      : 1;
        uint8_t us0       : 1;
        uint8_t us1       : 1;
        uint8_t us2       : 1;
        uint8_t us3       : 1;
        uint8_t mci0      : 1;
        uint8_t twi0      : 1;
        uint8_t twi1      : 1;
        uint8_t spi0      : 1;
        uint8_t ssc0      : 1;
        uint8_t tc0       : 1;
        uint8_t tc1       : 1;
        uint8_t tc2       : 1;
        uint8_t pwmc      : 1;
        uint8_t adc12b    : 1;
        uint8_t adc       : 1;
        uint8_t hdma      : 1;
        uint8_t udphs     : 1;
        uint8_t pid30     : 1; // not used on sam3u
        uint8_t pid31     : 1; // not use don sam3u
    } __attribute__((__packed__)) bits;
} pmc_pcer_t;

/**
 * PMC Peripheral Clock Disable Register, AT91 ARM Cortex-M3 based Microcontrollers
 * SAM3U Series, Preliminary, p. 486
 * 0: no effect
 * 1: disable corresponding peripheral clock
 */
typedef union
{
    uint32_t flat;
    struct
    {
        uint8_t reserved0 : 2;
        uint8_t rtc       : 1; // not used after datasheet
        uint8_t rtt       : 1; // not used after datasheet
        uint8_t wdg       : 1; // not used after datasheet
        uint8_t pmc       : 1; // not used after datasheet
        uint8_t efc0      : 1; // not used after datasheet
        uint8_t efc1      : 1; // not used after datasheet
        uint8_t dbgu      : 1;
        uint8_t hsmc4     : 1;
        uint8_t pioa      : 1;
        uint8_t piob      : 1;
        uint8_t pioc      : 1;
        uint8_t us0       : 1;
        uint8_t us1       : 1;
        uint8_t us2       : 1;
        uint8_t us3       : 1;
        uint8_t mci0      : 1;
        uint8_t twi0      : 1;
        uint8_t twi1      : 1;
        uint8_t spi0      : 1;
        uint8_t ssc0      : 1;
        uint8_t tc0       : 1;
        uint8_t tc1       : 1;
        uint8_t tc2       : 1;
        uint8_t pwmc      : 1;
        uint8_t adc12b    : 1;
        uint8_t adc       : 1;
        uint8_t hdma      : 1;
        uint8_t udphs     : 1;
        uint8_t pid30     : 1; // not used on sam3u
        uint8_t pid31     : 1; // not use don sam3u
    } __attribute__((__packed__)) bits;
} pmc_pcdr_t;

/**
 * PMC Peripheral Clock Status Register, AT91 ARM Cortex-M3 based Microcontrollers
 * SAM3U Series, Preliminary, p. 487
 * 0: peripheral clock disabled
 * 1: peripheral clock enabled
 */
typedef union
{
    uint32_t flat;
    struct
    {
        uint8_t reserved0 : 2;
        uint8_t rtc       : 1; // not used after datasheet
        uint8_t rtt       : 1; // not used after datasheet
        uint8_t wdg       : 1; // not used after datasheet
        uint8_t pmc       : 1; // not used after datasheet
        uint8_t efc0      : 1; // not used after datasheet
        uint8_t efc1      : 1; // not used after datasheet
        uint8_t dbgu      : 1;
        uint8_t hsmc4     : 1;
        uint8_t pioa      : 1;
        uint8_t piob      : 1;
        uint8_t pioc      : 1;
        uint8_t us0       : 1;
        uint8_t us1       : 1;
        uint8_t us2       : 1;
        uint8_t us3       : 1;
        uint8_t mci0      : 1;
        uint8_t twi0      : 1;
        uint8_t twi1      : 1;
        uint8_t spi0      : 1;
        uint8_t ssc0      : 1;
        uint8_t tc0       : 1;
        uint8_t tc1       : 1;
        uint8_t tc2       : 1;
        uint8_t pwmc      : 1;
        uint8_t adc12b    : 1;
        uint8_t adc       : 1;
        uint8_t hdma      : 1;
        uint8_t udphs     : 1;
        uint8_t pid30     : 1; // not used on sam3u
        uint8_t pid31     : 1; // not use don sam3u
    } __attribute__((__packed__)) bits;
} pmc_pcsr_t;

/**
 * PMC UTMI Clock Configuration Register, AT91 ARM Cortex-M3 based Microcontrollers
 * SAM3U Series, Preliminary, p. 488
 */
typedef union
{
    uint32_t flat;
    struct
    {
        uint16_t reserved0: 16;
        uint8_t upllen    :  1; // UTMI PLL enable
        uint8_t reserved1 :  3;
        uint8_t upllcount :  4; // UTMI PLL Start-up Time (in number of slow clock cycles times 8
        uint8_t reserved2 :  8; 
    } __attribute__((__packed__)) bits;
} pmc_uckr_t;

/**
 * PMC Clock Generator Main Oscillator Register, AT91 ARM Cortex-M3 based Microcontrollers
 * SAM3U Series, Preliminary, p. 489
 *
 * Note: You have to write 'key' together with every other operation, or else
 * the write gets aborted.
 */
typedef union
{
    uint32_t flat;
    struct
    {
        uint8_t moscxten   : 1; // main crtystal oscillator enable
        uint8_t moscxtby   : 1; // main crystal oscillator bypass
        uint8_t waitmode   : 1; // wait mode command
        uint8_t moscrcen   : 1; // main on-chip rc oscillator enable
        uint8_t moscrcf    : 3; // main on-chip rc oscillator frequency selection (0: 4MHz, 1: 8MHz, 2: 12MHz, 3: reserved)
        uint8_t reserved0  : 1;
        uint8_t moscxtst   : 8; // main crystal oscillator start-up time (in slow clock cycles times 8
        uint8_t key        : 8; // should be written at value 0x37
        uint8_t moscsel    : 1; // main oscillator selection (0: on-chip RC, 1: main crystal)
        uint8_t cfden      : 1; // clock failure detector enable
        uint8_t reserved1  : 6;
    } __attribute__((__packed__)) bits;
} pmc_mor_t;

#define PMC_MOR_KEY 0x37

/**
 * PMC Clock Generator Main Clock Frequency Register, AT91 ARM Cortex-M3 based Microcontrollers
 * SAM3U Series, Preliminary, p. 490
 * read-only
 */
typedef union
{
    uint32_t flat;
    struct
    {
        uint16_t mainf     : 16; // gives the number of main clock cycles within 16 slow clock periods
        uint8_t mainfrdy   :  1; // main clock ready
        uint16_t reserved0 : 15;
    } __attribute__((__packed__)) bits;
} pmc_mcfr_t;


/**
 * PMC Clock Generator PLLA Register, AT91 ARM Cortex-M3 based Microcontrollers
 * SAM3U Series, Preliminary, p. 491
 * Note: bit 29 must always be set to 1 when writing this register! 
 */ 
typedef union
{
    uint32_t flat;
    struct
    {
        uint8_t diva       :  8; // divider
        uint8_t pllacount  :  6; // plla counter, specifies the number of slow clock cycles times 8
        uint8_t stmode     :  2; // start mode
        uint16_t mula      : 11; // PLLA Multiplier
        uint8_t reserved0  :  2;
        uint8_t bit29      :  1; // ALWAYS SET THIS TO 1!!!!!!
        uint8_t reserved1  :  2;
    } __attribute__((__packed__)) bits;
} pmc_pllar_t;

#define PMC_PLLAR_STMODE_FAST_STARTUP 0
#define PMC_PLLAR_STMODE_NORMAL_STARTUP 2

/**
 * PMC Master Clock Register, AT91 ARM Cortex-M3 based Microcontrollers
 * SAM3U Series, Preliminary, p. 493
 */ 
typedef union
{
    uint32_t flat;
    struct
    {
        uint8_t css        :  2; // master clock source select
        uint8_t reserved0  :  2;
        uint8_t pres       :  3; // processor clock prescaler
        uint8_t reserved1  :  1;
        uint8_t reserved2  :  5;
        uint8_t uplldiv    :  1; // upll clock divider by 1 or 2
        uint8_t reserved3  :  2;
        uint16_t reserved4 : 16;
    } __attribute__((__packed__)) bits;
} pmc_mckr_t;

#define PMC_MCKR_CSS_SLOW_CLOCK 0
#define PMC_MCKR_CSS_MAIN_CLOCK 1
#define PMC_MCKR_CSS_PLLA_CLOCK 2
#define PMC_MCKR_CSS_UPLL_CLOCK 3

#define PMC_MCKR_PRES_DIV_1     0
#define PMC_MCKR_PRES_DIV_2     1
#define PMC_MCKR_PRES_DIV_4     2
#define PMC_MCKR_PRES_DIV_8     3
#define PMC_MCKR_PRES_DIV_16    4
#define PMC_MCKR_PRES_DIV_32    5
#define PMC_MCKR_PRES_DIV_64    6
#define PMC_MCKR_PRES_DIV_3     7

#define PMC_MCKR_UPLLDIV_1      0
#define PMC_MCKR_UPLLDIV_2      1

/**
 * PMC Programmable Clock Register, AT91 ARM Cortex-M3 based Microcontrollers
 * SAM3U Series, Preliminary, p. 494
 */ 
typedef union
{
    uint32_t flat;
    struct
    {
        uint8_t css       :  3; // programmable clock source selection
        uint8_t reserved0 :  1;
        uint8_t pres      :  3; // programmable clock prescaler
        uint8_t reserved1 :  1;
        uint8_t reserved2 :  8;
        uint16_t reserved3: 16;
    } __attribute__((__packed__)) bits;
} pmc_pck_t;

#define PMC_PCKX_CSS_SLOW_CLOCK   0
#define PMC_PCKX_CSS_MAIN_CLOCK   1
#define PMC_PCKX_CSS_PLLA_CLOCK   2
#define PMC_PCKX_CSS_UPLL_CLOCK   3
#define PMC_PCKX_CSS_MASTER_CLOCK 4

#define PMC_PCKX_PRES_DIV_1       0
#define PMC_PCKX_PRES_DIV_2       1
#define PMC_PCKX_PRES_DIV_4       2
#define PMC_PCKX_PRES_DIV_8       3
#define PMC_PCKX_PRES_DIV_16      4
#define PMC_PCKX_PRES_DIV_32      5
#define PMC_PCKX_PRES_DIV_64      6

/**
 * PMC Interrupt Enable Register, AT91 ARM Cortex-M3 based Microcontrollers
 * SAM3U Series, Preliminary, p. 495
 */ 
typedef union
{
    uint32_t flat;
    struct
    {
        uint8_t moscxts     :  1; // main crystal oscillator status interrupt enable
        uint8_t locka       :  1; // pll a lock interrupt enable
        uint8_t reserved0   :  1;
        uint8_t mckrdy      :  1; // master clock ready interrupt enable
        uint8_t reserved1   :  2;
        uint8_t locku       :  1; // utmi pll lock interrupt enable
        uint8_t reserved2   :  1;
        uint8_t pckrdy0     :  1; // programmable clock 0 ready interrupt enable
        uint8_t pckrdy1     :  1; // programmable clock 1 ready interrupt enable
        uint8_t pckrdy2     :  1; // programmable clock 2 ready interrupt enable
        uint8_t reserved3   :  5;
        uint8_t moscsels    :  1; // main oscillator selection status interrupt enable
        uint8_t moscrcs     :  1; // main on-chip rc status interrupt enable
        uint8_t cfdev       :  1; // clock failure detector event interrupt enable
        uint16_t reserved4  : 13;
    } __attribute__((__packed__)) bits;
} pmc_ier_t;

/**
 * PMC Interrupt Disable Register, AT91 ARM Cortex-M3 based Microcontrollers
 * SAM3U Series, Preliminary, p. 496
 */ 
typedef union
{
    uint32_t flat;
    struct
    {
        uint8_t moscxts     :  1; // main crystal oscillator status interrupt disable
        uint8_t locka       :  1; // pll a lock interrupt disable
        uint8_t reserved0   :  1;
        uint8_t mckrdy      :  1; // master clock ready interrupt disable
        uint8_t reserved1   :  2;
        uint8_t locku       :  1; // utmi pll lock interrupt disable
        uint8_t reserved2   :  1;
        uint8_t pckrdy0     :  1; // programmable clock 0 ready interrupt disable
        uint8_t pckrdy1     :  1; // programmable clock 1 ready interrupt disable
        uint8_t pckrdy2     :  1; // programmable clock 2 ready interrupt disable
        uint8_t reserved3   :  5;
        uint8_t moscsels    :  1; // main oscillator selection status interrupt disable
        uint8_t moscrcs     :  1; // main on-chip rc status interrupt disable
        uint8_t cfdev       :  1; // clock failure detector event interrupt disable
        uint16_t reserved4  : 13;
    } __attribute__((__packed__)) bits;
} pmc_idr_t;

/**
 * PMC Status Register, AT91 ARM Cortex-M3 based Microcontrollers
 * SAM3U Series, Preliminary, p. 497
 */ 
typedef union
{
    uint32_t flat;
    struct
    {
        uint8_t moscxts     :  1; // main crystal oscillator stabilized
        uint8_t locka       :  1; // pll a locked
        uint8_t reserved0   :  1;
        uint8_t mckrdy      :  1; // master clock ready
        uint8_t reserved1   :  2;
        uint8_t locku       :  1; // utmi pll locked
        uint8_t oscsels     :  1; // Slow clock oscillator selection (0: rc osc, 1: external clock)
        uint8_t pckrdy0     :  1; // programmable clock 0 ready
        uint8_t pckrdy1     :  1; // programmable clock 1 ready
        uint8_t pckrdy2     :  1; // programmable clock 2 ready
        uint8_t reserved2   :  5;
        uint8_t moscsels    :  1; // main oscillator selection (0: done, 1: in progress
        uint8_t moscrcs     :  1; // main on-chip rc stabilized
        uint8_t cfdev       :  1; // clock failure detector event since last read
        uint8_t cfds        :  1; // clock failure detected
        uint8_t fos         :  1; // clock failure detector fault output status
        uint16_t reserved3  : 11;
    } __attribute__((__packed__)) bits;
} pmc_sr_t;

/**
 * PMC Interrupt Mask Register, AT91 ARM Cortex-M3 based Microcontrollers
 * SAM3U Series, Preliminary, p. 499
 */ 
typedef union
{
    uint32_t flat;
    struct
    {
        uint8_t moscxts     :  1; // main crystal oscillator status interrupt mask
        uint8_t locka       :  1; // pll a lock interrupt mask
        uint8_t reserved0   :  1;
        uint8_t mckrdy      :  1; // master clock ready interrupt mask
        uint8_t reserved1   :  2;
        uint8_t locku       :  1; // utmi pll lock interrupt mask
        uint8_t reserved2   :  1;
        uint8_t pckrdy0     :  1; // programmable clock 0 ready interrupt mask
        uint8_t pckrdy1     :  1; // programmable clock 1 ready interrupt mask
        uint8_t pckrdy2     :  1; // programmable clock 2 ready interrupt mask
        uint8_t reserved3   :  5;
        uint8_t moscsels    :  1; // main oscillator selection status interrupt mask
        uint8_t moscrcs     :  1; // main on-chip rc status interrupt mask
        uint8_t cfdev       :  1; // clock failure detector event interrupt mask
        uint16_t reserved4  : 13;
    } __attribute__((__packed__)) bits;
} pmc_imr_t;

/**
 * PMC Fast Startup Mode Register, AT91 ARM Cortex-M3 based Microcontrollers
 * SAM3U Series, Preliminary, p. 500
 */ 
typedef union
{
    uint32_t flat;
    struct
    {
        uint8_t fstt0       :  1; // fast startup input enable 0
        uint8_t fstt1       :  1; // fast startup input enable 1
        uint8_t fstt2       :  1; // fast startup input enable 2
        uint8_t fstt3       :  1; // fast startup input enable 3
        uint8_t fstt4       :  1; // fast startup input enable 4
        uint8_t fstt5       :  1; // fast startup input enable 5
        uint8_t fstt6       :  1; // fast startup input enable 6
        uint8_t fstt7       :  1; // fast startup input enable 7
        uint8_t fstt8       :  1; // fast startup input enable 8
        uint8_t fstt9       :  1; // fast startup input enable 9
        uint8_t fstt10      :  1; // fast startup input enable 10
        uint8_t fstt11      :  1; // fast startup input enable 11
        uint8_t fstt12      :  1; // fast startup input enable 12
        uint8_t fstt13      :  1; // fast startup input enable 13
        uint8_t fstt14      :  1; // fast startup input enable 14
        uint8_t fstt15      :  1; // fast startup input enable 15
        uint8_t rttal       :  1; // RTT alarm enable
        uint8_t rtcal       :  1; // RTC alarm enable
        uint8_t usbal       :  1; // USB alarm enable
        uint8_t reserved0   :  1;
        uint8_t lpm         :  1; // low power mode (0: wfi or wfe makes processor go into idle mode, 1: wfe makes processor go into wait mode)
        uint16_t reserved1  : 11;
    } __attribute__((__packed__)) bits;
} pmc_fsmr_t;

/**
 * PMC Fast Startup Polarity Register, AT91 ARM Cortex-M3 based Microcontrollers
 * SAM3U Series, Preliminary, p. 501
 */ 
typedef union
{
    uint32_t flat;
    struct
    {
        uint8_t fstt0       :  1; // fast startup input 0
        uint8_t fstt1       :  1; // fast startup input 1
        uint8_t fstt2       :  1; // fast startup input 2
        uint8_t fstt3       :  1; // fast startup input 3
        uint8_t fstt4       :  1; // fast startup input 4
        uint8_t fstt5       :  1; // fast startup input 5
        uint8_t fstt6       :  1; // fast startup input 6
        uint8_t fstt7       :  1; // fast startup input 7
        uint8_t fstt8       :  1; // fast startup input 8
        uint8_t fstt9       :  1; // fast startup input 9
        uint8_t fstt10      :  1; // fast startup input 10
        uint8_t fstt11      :  1; // fast startup input 11
        uint8_t fstt12      :  1; // fast startup input 12
        uint8_t fstt13      :  1; // fast startup input 13
        uint8_t fstt14      :  1; // fast startup input 14
        uint8_t fstt15      :  1; // fast startup input 15
        uint16_t reserved0  : 16;
    } __attribute__((__packed__)) bits;
} pmc_fspr_t;

/**
 * PMC Fault Output Clear Register, AT91 ARM Cortex-M3 based Microcontrollers
 * SAM3U Series, Preliminary, p. 502
 */ 
typedef union
{
    uint32_t flat;
    struct
    {
        uint8_t foclr       :  1; // fault output clear
        uint32_t reserved0  : 31;
    } __attribute__((__packed__)) bits;
} pmc_focr_t;

typedef struct
{
    volatile pmc_pcer_t pcer; // Peripheral Clock Enable Register
    volatile pmc_pcdr_t pcdr; // Peripheral Clock Disable Register
    volatile pmc_pcsr_t pcsr; // Peripheral Clock Status Register
} pmc_pc_t;


#endif // PMCHARDWARE_H
