// $Id: HPLGeneralIOPinM.nc,v 1.1.2.2 2005-05-10 18:13:41 idgay Exp $

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

generic module HPLGeneralIOPinM (uint8_t port_addr, 
				 uint8_t ddr_addr, 
				 uint8_t pin)
{
    provides interface GeneralIO as IO;
}
implementation
{
#define port (*(volatile uint8_t *)port_addr)
#define ddr (*(volatile uint8_t *)ddr_addr)

    async command bool IO.get()        { return READ_BIT (port, pin); }
    async command void IO.set()        { atomic SET_BIT  (port, pin); }
    async command void IO.clr()        { atomic CLR_BIT  (port, pin); }
    async command void IO.toggle()     { atomic FLIP_BIT (port, pin); }
    
    async command void IO.makeInput()  { atomic CLR_BIT  (ddr, pin);  }
    async command void IO.makeOutput() { atomic SET_BIT  (ddr, pin);  }
}

