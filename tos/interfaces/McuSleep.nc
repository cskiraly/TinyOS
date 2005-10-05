/// $Id: McuSleep.nc,v 1.1.2.1 2005-10-05 06:03:55 mturon Exp $

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
 * Primitives for controlling the processor sleep state.  
 * This interface is described in TEP112.  
 * 
 * NOTE: This implementation does not conform exactly to the specification 
 * yet, and is essentially a merged set of the three interfaces described.  
 * The third "power override" interface is simplified currently using a 
 * tinyos-1.x style enable/disable legacy interface.
 *
 * <pre>
 *  $Id: McuSleep.nc,v 1.1.2.1 2005-10-05 06:03:55 mturon Exp $
 * </pre>
 *
 * @author Martin Turon <mturon@xbow.com>
 */

interface McuSleep {
    async command error_t enable();
    async command error_t disable();

    /** Tells the Power Management component to recalculate the sleep state. */
    async command void    dirty();

    /** Called by Scheduler to put the MCU to sleep. */
    async command void    sleep();
}
