// $Id: HPLInterruptPinM.nc,v 1.1.2.2 2005-07-31 03:17:53 mturon Exp $

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

/**
 * Interrupt interface access for interrupt capable GPIO pins.
 */
generic module HPLInterruptPinM (uint8_t ctrl_addr, 
				 uint8_t edge0_addr, 
				 uint8_t edge1_addr, 
				 uint8_t bit)
{
    provides {
	interface HPLInterrupt as Irq;
    }
    uses {
	interface HPLInterruptSig as IrqSignal;
    }
}
implementation
{
#define ctrl  (*(volatile uint8_t *)ctrl_addr)
#define edge0 (*(volatile uint8_t *)edge0_addr)
#define edge1 (*(volatile uint8_t *)edge1_addr)

    inline async command bool Irq.getValue()   { return READ_BIT (EIFR, bit); }
    inline async command void Irq.clear()      { CLR_BIT  (EIFR, bit); }
    
    inline async command void Irq.enable()     { SET_BIT  (EIMSK, bit);  }
    inline async command void Irq.disable()    { CLR_BIT  (EIMSK, bit);  }

    inline async command void Irq.edge(bool low_to_high) { 
        SET_BIT(ctrl, edge1);	            // use edge mode
        if (low_to_high) {
	    SET_BIT(ctrl, edge0);          // trigger on rising level
        } else {
	    CLR_BIT(ctrl, edge0);          // trigger on falling level
	}
    }

    /** 
     * Forward the external interrupt event.  This ties the statically
     * allocated interrupt vector SIG_INTERRUPT##bit to a particular
     * pin passed in via the generic component instantiation.
     */
    async event void IrqSignal.fired() { signal Irq.fired(); }

    default async event void Irq.fired() { }
}
