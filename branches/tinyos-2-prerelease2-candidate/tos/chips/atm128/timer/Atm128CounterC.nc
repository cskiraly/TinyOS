//$Id: Atm128CounterC.nc,v 1.1.2.1 2005-10-27 20:31:27 idgay Exp $

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

// Convert ATmega128 hardware timer to TinyOS CounterBase.
generic module Atm128CounterC(typedef frequency_tag,
			      typedef timer_size @integer())
{
  provides interface Counter<frequency_tag,timer_size> as Counter;
  uses interface HplTimer<timer_size> as Timer;
}
implementation
{
  async command timer_size Counter.get()
  {
    return call Timer.get();
  }

  async command bool Counter.isOverflowPending()
  {
    return call Timer.test();
  }

  async command void Counter.clearOverflow()
  {
    call Timer.reset();
  }

  async event void Timer.overflow()
  {
    signal Counter.overflow();
  }
}

