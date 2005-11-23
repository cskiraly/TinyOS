/*									tab:4
 * "Copyright (c) 2000-2005 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 */
/*
 *
 * Authors:		Joe Polastre
 *
 * $Id: HPLUSART0C.nc,v 1.1.2.2 2005-11-23 17:59:17 phihup Exp $
 */

#include "msp430BusResource.h"
configuration HPLUSART0C
{
  provides {
    interface Init;
    interface HPLUSARTControl;
    interface HPLUSARTFeedback;
    interface Resource[uint8_t id];
    interface ResourceUser;
  }
}
implementation
{
  components HPLUSART0P
	, new FcfsArbiterC(MSP430_HPLUSART0_RESOURCE) as ResourceArbiter
	, MSP430GeneralIOC as IO;

  Init = ResourceArbiter;

  Resource = ResourceArbiter;
  ResourceUser = ResourceArbiter;

  HPLUSARTControl = HPLUSART0P;
  HPLUSARTFeedback = HPLUSART0P;

  HPLUSART0P.PinUTXD0 -> IO.UTXD0;
  HPLUSART0P.PinURXD0 -> IO.URXD0;
  HPLUSART0P.PinSIMO0 -> IO.SIMO0;
  HPLUSART0P.PinSOMI0 -> IO.SOMI0;
  HPLUSART0P.PinUCLK0 -> IO.UCLK0;
}

