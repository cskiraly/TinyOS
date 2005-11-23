/// $Id: HplTimer0AsyncC.nc,v 1.1.2.1 2005-11-23 00:15:37 scipio Exp $

/*
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

/**
 * The TOSSIM implementation of the Atm128 Timer0.
 *
 * @author Philip Levis <pal@cs.stanford.edu>
 * @author Martin Turon <mturon@xbow.com>
 * @author David Gay <dgay@intel-research.net>
 */
#include <Atm128Timer.h>

configuration HplTimer0AsyncC
{
  provides {
    // 8-bit Timers
    interface HplTimer<uint8_t>   as Timer0;
    interface HplTimerCtrl8       as Timer0Ctrl;
    interface HplCompare<uint8_t> as Compare0;
  }
}
implementation {
  components HplCounter0C, new HplAtm128CompareC(uint8_t,
						 ATM128_OCR0,
						 ATM128_TIMSK,
						 OCIE0,
						 ATM128_TIFR,
						 OCF0);

  Timer0 = HplCounter0C;
  Timer0Ctrl = HplCounter0C;
  Compare0 = HplAtm128CompareC;

  HplAtm128CompareC.Timer -> HplCounter0C;
  HplAtm128CompareC.TimerCtrl -> HplCounter0C;
  HplAtm128CompareC.Notify -> HplCounter0C;
  
}
