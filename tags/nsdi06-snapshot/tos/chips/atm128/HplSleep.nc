/**
 * "Copyright (c) 2005 Crossbow Technology, Inc. 
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
 * An interface for accessing the Mcu Control Register (MCUCR) 
 * that controls the sleep states on the ATmega128.
 *
 * <pre>
 *  $Id: HplSleep.nc,v 1.1.2.1 2005-10-05 06:04:54 mturon Exp $
 * </pre>
 *
 * @author Martin Turon <mturon@xbow.com>
 */

#include "Atm128Power.h"

interface HplSleep {
    /** Utility command to read the MCU control register (MCUCR). */
    async command Atm128SleepControl_t getControl();

    /** Utility command to write the MCU control register (MCUCR). */
    async command void setControl( Atm128SleepControl_t x );

    /** Utility command to enable sleep. */
    async command void enable();

    /** Utility command to force active mode. */
    async command void disable();

    /** Sets the sleep mode to use next sleep instruction. */
    async command void setMode(uint8_t mode);

    /** Returns the sleep mode to be used next sleep instruction. */
    async command uint8_t getMode();
}
