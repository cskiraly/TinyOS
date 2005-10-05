/**
 * "Copyright (c) 2005 Crossbow Technology, Inc. 
 *  Copyright (c) 2000-2005 The Regents of the University  of California.
 *  All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and
 * its documentation for any purpose, without fee, and without written
 * agreement is hereby granted, provided that the above copyright
 * notice, the following two paragraphs and the author appear in all
 * copies of this software.
 * 
 * IN NO EVENT SHALL THE COPYRIGHT HOLDERS AND CONTRIBUTORS BE LIABLE TO ANY 
 * PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES
 * ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN
 * IF THE COPYRIGHT HOLDERS AND CONTRIBUTORS HAVE BEEN ADVISED OF THE 
 * POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE COPYRIGHT HOLDERS AND CONTRIBUTORS SPECIFICALLY DISCLAIM ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
 * FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS ON AN 
 * "AS IS" BASIS, AND THE COPYRIGHT HOLDERS AND CONTRIBUTORS HAVE NO OBLIGATION
 * TO PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 */

/**
 * Primitives for controlling the processor sleep state on a ATmega128
 * microcontroller.  This module gets called whenever there are no 
 * pending tasks in the scheduler.  Hardware subsytems are to call into
 * this module to specify that a particular sleep mode is required or 
 * the overall power state has otherwise been "dirtyed".   *
 *
 * <pre>
 *  $Id: HplSleepC.nc,v 1.1.2.1 2005-10-05 06:04:54 mturon Exp $
 * </pre>
 *
 * @author Martin Turon <mturon@xbow.com>
 * @author Robert Szewczyk
 */

module HplSleepC {
    provides {
	interface McuSleep;
	interface HplSleep;
    }
}
implementation {  

    /** 
     * Internal state flags for power manager component.
     *
     * Dirty bit is specified in TEP 112.  
     * Next state may be better stored in hardware register.  
     * Enabled count may be single bit in hardware register as well -- TBD.
     */
    struct {
	uint8_t dirty    : 1; //!< Recalculation of deep sleep state required?
	uint8_t state    : 3; //!< Next deep sleep state
	 int8_t enabled  : 4; //!< Count of components that enable deep sleep
    } sleep_flags;

    uint8_t getSleepLevel() {
	if (TIMSK & (~((1<<OCIE0) | (1<<TOIE0)))) { 
            // Are the external timers running?
	    return ATM128_SLEEP_IDLE;

	} else if (bit_is_set(SPCR, SPIE)) {  // SPI (Radio stack on mica) 
	    return ATM128_SLEEP_IDLE;

	} else if ((UCSR0B & ((1<<RXEN)|(1<<RXCIE) | (1<<TXEN)|(1<<TXCIE))) ||
		   (UCSR1B & ((1<<RXEN)|(1<<RXCIE) | (1<<TXEN)|(1<<TXCIE)))) {
	    // UART channel is active so we must keep the CPU clock running
	    return ATM128_SLEEP_IDLE;

	} else if (bit_is_set(ADCSR, ADEN)) { // ADC is enabled
	    return ATM128_SLEEP_ADC;

	} else if (TIMSK & ((1<<OCIE0) | (1<<TOIE0))) {
	    // Use extended standby if only a few ticks are left until the
	    // next Timer0 interrupt.
	    uint8_t diff;
	    diff = OCR0 - TCNT0;
	    if (diff < 16) 
		return ATM128_SLEEP_EXTENDED_STANDBY;

	    // Otherwise, go into power save mode -- this is the 
	    // lowest state for a typical TinyOS system. (~10uA)
	    return ATM128_SLEEP_POWER_SAVE;

	} else {
	    // Typical TinyOS systems will not go into such a full power down 
	    // mode since Timer0 feeds system timer
	    return ATM128_SLEEP_POWER_DOWN;
	}
    }

    void adjustSleepLevel() {
	// Do nothing unless the power state requires recalculation.
	if (sleep_flags.dirty) {
	    uint8_t new_state = ATM128_SLEEP_IDLE; // default to IDLE

	    if (sleep_flags.enabled) {             // if deep sleep enabled
		new_state = getSleepLevel();       // recalculate level
	    }

	    call HplSleep.setMode(new_state);      // Set the new power state.
	    sleep_flags.dirty = 0;                 // Clear out the dirty bit.
	}
    }    

    async command error_t McuSleep.enable() {
      atomic sleep_flags.enabled = 1;
      return SUCCESS;
    }

    async command error_t McuSleep.disable() {
      atomic sleep_flags.enabled = 0;
      return SUCCESS;
    }

    async command void McuSleep.dirty() {
      atomic sleep_flags.dirty = 1;
    }

    //===  Interface to task scheduler. ===============================

    /** Called in atomic context by scheduler */
    async command void McuSleep.sleep() {
	__nesc_atomic_sleep();
    }

    //=== MCU Control Register utility commands. ==========================

    /** Utility command to read the MCU control register (MCUCR). */
    async command Atm128SleepControl_t HplSleep.getControl() { 
	return *(Atm128SleepControl_t*)&MCUCR; 
    }
    /** Utility command to write the MCU control register (MCUCR). */
    async command void HplSleep.setControl( Atm128SleepControl_t x ) { 
	MCUCR = x.flat; 
    }

    /** Utility command to enable sleep. */
    async command void HplSleep.enable()  { SET_BIT(MCUCR, SE); }

    /** Utility command to force active mode. */
    async command void HplSleep.disable() { CLR_BIT(MCUCR, SE); }

    /** Sets the sleep mode to use next sleep instruction. */
    async command void HplSleep.setMode(uint8_t mode) { 
	Atm128SleepControl_t l_mode;
	l_mode.flat    = MCUCR;
	l_mode.bits.sm = mode;
	MCUCR          = l_mode.flat;
    }

    /** Returns the sleep mode to be used next sleep instruction. */
    async command uint8_t HplSleep.getMode() { 
	return (call HplSleep.getControl()).bits.sm;
    }
}
