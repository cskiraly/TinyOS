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
 * $Id: HPLUSART1C.nc,v 1.1.2.2 2005-11-23 17:59:17 phihup Exp $
 */

#include "msp430BusResource.h"
configuration HPLUSART1C
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
  components HPLUSART1P
           , new FCFSArbiter(MSP430_HPLUSART1_RESOURCE) as ResourceArbiter
           , MSP430GeneralIOC as IO;

  Init = ResourceArbiter;

  Resource = ResourceArbiter;
  ResourceUser = ResourceArbiter;

  HPLUSARTControl = HPLUSART1P;
  HPLUSARTFeedback = HPLUSART1P;

  HPLUSART1M.PinUTXD1 -> IO.UTXD1;
  HPLUSART1M.PinURXD1 -> IO.URXD1;
  HPLUSART1M.PinSIMO1 -> IO.SIMO1;
  HPLUSART1M.PinSOMI1 -> IO.SOMI1;
  HPLUSART1M.PinUCLK1 -> IO.UCLK1;
}
