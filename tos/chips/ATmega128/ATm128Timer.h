/// $Id: ATm128Timer.h,v 1.1.2.5 2005-02-09 02:11:06 mturon Exp $

/**
 * Copyright (c) 2004-2005 Crossbow Technology, Inc.  All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL CROSSBOW TECHNOLOGY OR ANY OF ITS LICENSORS BE LIABLE TO 
 * ANY PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL 
 * DAMAGES ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN
 * IF CROSSBOW OR ITS LICENSOR HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH 
 * DAMAGE. 
 *
 * CROSSBOW TECHNOLOGY AND ITS LICENSORS SPECIFICALLY DISCLAIM ALL WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY 
 * AND FITNESS FOR A PARTICULAR PURPOSE. THE SOFTWARE PROVIDED HEREUNDER IS 
 * ON AN "AS IS" BASIS, AND NEITHER CROSSBOW NOR ANY LICENSOR HAS ANY 
 * OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR 
 * MODIFICATIONS.
 */

/// @author Martin Turon <mturon@xbow.com>

#ifndef _H_ATm128Timer_h
#define _H_ATm128Timer_h

//====================== 8 bit Timers ==================================

// Timer0 and Timer2 are 8-bit timers.

/** 8-bit Timer Clock Source Select Options */
enum {
    ATM128_CLK8_OFF = 0,
    ATM128_CLK8_NORMAL = 1,
    ATM128_CLK8_DIVIDE_8,
    ATM128_CLK8_DIVIDE_32,
    ATM128_CLK8_DIVIDE_64,
    ATM128_CLK8_DIVIDE_128,
    ATM128_CLK8_DIVIDE_256,
    ATM128_CLK8_DIVIDE_1024,
};

/** 8-bit Waveform Generation Modes */
enum {
    ATM128_WAVE8_NORMAL = 0,
    ATM128_WAVE8_PWM,
    ATM128_WAVE8_CTC,
    ATM128_WAVE8_PWM_FAST,
};

/** 8-bit Timer Control Register */
typedef struct
{
    uint8_t foc   : 1;  //!< Force Output Compare
    uint8_t wgm0  : 1;  //!< Waveform generation mode (low bit)
    uint8_t com   : 2;  //!< Compare Match Output
    uint8_t wgm1  : 1;  //!< Waveform generation mode (high bit)
    uint8_t cs    : 3;  //!< Clock Source Select
} ATm128TimerControl_t;

typedef ATm128TimerControl_t ATm128_TCCR0_t;  //!< Timer0 Control Register
typedef uint8_t ATm128_TCNT0_t;               //!< Timer0 Control Register
typedef uint8_t ATm128_OCR0_t;         //!< Timer0 Output Compare Register

typedef ATm128TimerControl_t ATm128_TCCR2_t;  //!< Timer2 Control Register
typedef uint8_t ATm128_TCNT2_t;               //!< Timer2 Control Register
typedef uint8_t ATm128_OCR2_t;         //!< Timer2 Output Compare Register
// Timer2 shares compare lines with Timer1C

/** Asynchronous Status Register -- Timer0 */
typedef struct
{
    uint8_t rsvd   : 4;  //!< Reserved
    uint8_t as0    : 1;  //!< Asynchronous Timer/Counter (off=CPU,on=32KHz osc)
    uint8_t tcn0ub : 1;  //!< Timer0 Update Busy
    uint8_t ocr0ub : 1;  //!< Timer0 Output Compare Register Update Busy
    uint8_t tcr0ub : 1;  //!< Timer0 Control Resgister Update Busy
} ATm128_ASSR_t;

/** Timer/Counter Interrupt Mask Register */
typedef struct
{
    uint8_t ocie2 : 1; //!< Timer2 Output Compare Interrupt Enable
    uint8_t toie2 : 1; //!< Timer2 Overflow Interrupt Enable
    uint8_t ticie1: 1; //!< Timer1 Input Capture Enable
    uint8_t ocie1A: 1; //!< Timer1 Output Compare A Interrupt Enable
    uint8_t ocie1B: 1; //!< Timer1 Output Compare B Interrupt Enable
    uint8_t toie1 : 1; //!< Timer1 Overflow Interrupt Enable
    uint8_t ocie0 : 1; //!< Timer0 Output Compare Interrupt Enable
    uint8_t toie0 : 1; //!< Timer0 Overflow Interrupt Enable
} ATm128_TIMSK_t;
// + Note: Contains some 16-bit Timer flags

/** Timer/Counter Interrupt Flag Register */
typedef struct
{
    uint8_t ocf2  : 1; //!< Timer2 Output Compare Flag
    uint8_t tov2  : 1; //!< Timer2 Overflow Flag
    uint8_t icf1  : 1; //!< Timer1 Input Capture Flag 
    uint8_t ocf1A : 1; //!< Timer1 Output Compare A Flag
    uint8_t ocf1B : 1; //!< Timer1 Output Compare B Flag
    uint8_t tov1  : 1; //!< Timer1 Overflow Flag
    uint8_t ocf0  : 1; //!< Timer0 Output Compare Flag
    uint8_t tov0  : 1; //!< Timer0 Overflow Flag
} ATm128_TIFR_t;
// + Note: Contains some 16-bit Timer flags

/** Timer/Counter Interrupt Flag Register */
typedef struct
{
    uint8_t tsm    : 1; //!< Timer/Counter Synchronization Mode
    uint8_t rsvd   : 3; //!< Reserved
    uint8_t acme   : 1; //!< 
    uint8_t pud    : 1; //!< 
    uint8_t psr0   : 1; //!< Prescaler Reset Timer0
    uint8_t psr321 : 1; //!< Prescaler Reset Timer1,2,3
} ATm128_SFIOR_t;


//====================== 16 bit Timers ==================================

// Timer1 and Timer3 are both 16-bit, and have three compare channels: (A,B,C)

enum {
    ATM128_TIMER_COMPARE_NORMAL = 0,
    ATM128_TIMER_COMPARE_TOGGLE,
    ATM128_TIMER_COMPARE_CLEAR,
    ATM128_TIMER_COMPARE_SET
};

/** Timer/Counter Control Register A Type */
typedef struct
{
    uint8_t comA  : 2;   //!< Compare Match Output A
    uint8_t comB  : 2;   //!< Compare Match Output B
    uint8_t comC  : 2;   //!< Compare Match Output C
    uint8_t wgm10 : 2;   //!< Waveform generation mode
} ATm128TimerCtrlCompare_t;

/** Timer1 Compare Control Register A */
typedef ATm128TimerCtrlCompare_t ATm128_TCCR1A_t;

/** Timer3 Compare Control Register A */
typedef ATm128TimerCtrlCompare_t ATm128_TCCR3A_t;

enum {
    ATM128_CLK16_OFF = 0,
    ATM128_CLK16_NORMAL = 1,
    ATM128_CLK16_DIVIDE_8,
    ATM128_CLK16_DIVIDE_64,
    ATM128_CLK16_DIVIDE_256,
    ATM128_CLK16_EXT_FALLING,
    ATM128_CLK16_EXT_RISING
};

/** 16-bit Waveform Generation Modes */
enum {
    ATM128_WAVE16_NORMAL = 0,
    ATM128_WAVE16_PWM_8BIT,
    ATM128_WAVE16_PWM_9BIT,
    ATM128_WAVE16_PWM_10BIT,
    ATM128_WAVE16_CTC_COMPARE,
    ATM128_WAVE16_PWM_FAST_8BIT,
    ATM128_WAVE16_PWM_FAST_9BIT,
    ATM128_WAVE16_PWM_FAST_10BIT,
    ATM128_WAVE16_PWM_CAPTURE_LOW,
    ATM128_WAVE16_PWM_COMPARE_LOW,
    ATM128_WAVE16_PWM_CAPTURE_HIGH,
    ATM128_WAVE16_PWM_COMPARE_HIGH,
    ATM128_WAVE16_CTC_CAPTURE,
    ATM128_WAVE16_RESERVED,
    ATM128_WAVE16_PWM_FAST_CAPTURE,
    ATM128_WAVE16_PWM_FAST_COMPARE,
};

/** Timer/Counter Control Register B Type */
typedef struct
{
    uint8_t icnc1 : 1;   //!< Input Capture Noise Canceler
    uint8_t ices1 : 1;   //!< Input Capture Edge Select (1=rising, 0=falling)
    uint8_t rsvd  : 1;   //!< Reserved
    uint8_t wgm32 : 2;   //!< Waveform generation mode
    uint8_t cs    : 3;   //!< Clock Source Select
} ATm128TimerCtrlCapture_t;

/** Timer1 Control Register B */
typedef ATm128TimerCtrlCapture_t ATm128_TCCR1B_t;

/** Timer3 Control Register B */
typedef ATm128TimerCtrlCapture_t ATm128_TCCR3B_t;

/** Timer/Counter Control Register C Type */
typedef struct
{
    uint8_t focA  : 1;   //!< Force Output Compare Channel A
    uint8_t focB  : 1;   //!< Force Output Compare Channel B
    uint8_t focC  : 1;   //!< Force Output Compare Channel C
    uint8_t rsvd  : 5;   //!< Reserved
} ATm128TimerCtrlClock_t;

/** Timer1 Control Register B */
typedef ATm128TimerCtrlClock_t ATm128_TCCR1C_t;

/** Timer3 Control Register B */
typedef ATm128TimerCtrlClock_t ATm128_TCCR3C_t;

// Read/Write these 16-bit Timer registers according to p.112:
// Access as bytes.  Read low before high.  Write high before low. 
typedef uint8_t ATm128_TCNT1H_t;  //!< Timer1 Register
typedef uint8_t ATm128_TCNT1L_t;  //!< Timer1 Register
typedef uint8_t ATm128_TCNT3H_t;  //!< Timer3 Register
typedef uint8_t ATm128_TCNT3L_t;  //!< Timer3 Register

/** Contains value to continuously compare with Timer1 */
typedef uint8_t ATm128_OCR1AH_t;  //!< Output Compare Register 1A
typedef uint8_t ATm128_OCR1AL_t;  //!< Output Compare Register 1A
typedef uint8_t ATm128_OCR1BH_t;  //!< Output Compare Register 1B
typedef uint8_t ATm128_OCR1BL_t;  //!< Output Compare Register 1B
typedef uint8_t ATm128_OCR1CH_t;  //!< Output Compare Register 1C
typedef uint8_t ATm128_OCR1CL_t;  //!< Output Compare Register 1C

/** Contains value to continuously compare with Timer3 */
typedef uint8_t ATm128_OCR3AH_t;  //!< Output Compare Register 3A
typedef uint8_t ATm128_OCR3AL_t;  //!< Output Compare Register 3A
typedef uint8_t ATm128_OCR3BH_t;  //!< Output Compare Register 3B
typedef uint8_t ATm128_OCR3BL_t;  //!< Output Compare Register 3B
typedef uint8_t ATm128_OCR3CH_t;  //!< Output Compare Register 3C
typedef uint8_t ATm128_OCR3CL_t;  //!< Output Compare Register 3C

/** Contains counter value when event occurs on ICPn pin. */
typedef uint8_t ATm128_ICR1H_t;  //!< Input Capture Register 1
typedef uint8_t ATm128_ICR1L_t;  //!< Input Capture Register 1
typedef uint8_t ATm128_ICR3H_t;  //!< Input Capture Register 3
typedef uint8_t ATm128_ICR3L_t;  //!< Input Capture Register 3

/** Extended Timer/Counter Interrupt Mask Register */
typedef struct
{
    uint8_t rsvd  : 2; //!< Timer2 Output Compare Interrupt Enable
    uint8_t ticie3: 1; //!< Timer3 Input Capture Interrupt Enable
    uint8_t ocie3A: 1; //!< Timer3 Output Compare A Interrupt Enable
    uint8_t ocie3B: 1; //!< Timer3 Output Compare B Interrupt Enable
    uint8_t toie3 : 1; //!< Timer3 Overflow Interrupt Enable
    uint8_t ocie3C: 1; //!< Timer3 Output Compare C Interrupt Enable
    uint8_t ocie1C: 1; //!< Timer1 Output Compare C Interrupt Enable
} ATm128_ETIMSK_t;

/** Extended Timer/Counter Interrupt Flag Register */
typedef struct
{
    uint8_t rsvd  : 2; //!< Reserved
    uint8_t icf3  : 1; //!< Timer3 Input Capture Flag 
    uint8_t ocf3A : 1; //!< Timer3 Output Compare A Flag
    uint8_t ocf3B : 1; //!< Timer3 Output Compare B Flag
    uint8_t tov3  : 1; //!< Timer/Counter Overflow Flag
    uint8_t ocf3C : 1; //!< Timer3 Output Compare C Flag
    uint8_t ocf1C : 1; //!< Timer1 Output Compare C Flag
} ATm128_ETIFR_t;

#endif //_H_ATm128Timer_h

