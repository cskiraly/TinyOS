//$Id: CastCounterM.nc,v 1.1.2.1 2005-03-30 17:54:52 cssharp Exp $

/* "Copyright (c) 2000-2003 The Regents of the University of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement
 * is hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY
 * OF CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 */

// @author Cory Sharp <cssharp@eecs.berkeley.edu>

// Cast a 32-bit CounterBase into a standard 32-bit Counter.
generic module CastCounterM( typedef frequency_tag )
{
  provides interface Counter<frequency_tag> as Counter;
  uses interface CounterBase<frequency_tag,uint32_t> as CounterFrom;
}
implementation
{
  async command uint32_t Counter.get()
  {
    return call CounterFrom.get();
  }

  async command bool Counter.isOverflowPending()
  {
    return call CounterFrom.isOverflowPending();
  }

  async command void Counter.clearOverflow()
  {
    call CounterFrom.clearOverflow();
  }

  async event void CounterFrom.overflow()
  {
    signal Counter.overflow();
  }

  default async event void Counter.overflow()
  {
  }
}

