//$Id: WidenCounterM.nc,v 1.1.2.2 2005-02-11 02:12:57 cssharp Exp $

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

//@author Cory Sharp <cssharp@eecs.berkeley.edu>

// The TinyOS Timer interfaces are discussed in TEP 102.

generic module WidenCounterM(
  typedef to_size_type,
  typedef from_size_type,
  typedef upper_count_type,
  typedef frequency_tag )
{
  provides interface CounterBase<to_size_type,frequency_tag> as Counter;
  uses interface CounterBase<from_size_type,frequency_tag> as CounterFrom;
  uses interface MathOps<to_size_type> as MathTo;
  uses interface MathOps<from_size_type> as MathFrom;
  uses interface MathOps<upper_count_type> as MathUpper;
}
implementation
{
  upper_count_type m_upper;

  async command to_size_type Counter.get()
  {
    to_size_type rv;
    atomic
    {
      upper_count_type high = m_upper;
      from_size_type low = call CounterFrom.get();
      if( call CounterFrom.isOverflowPending() )
      {
	// If we signalled CounterFrom.overflow, that might trigger a
	// Counter.overflow, which breaks atomicity.  The right thing to do
	// increment a cached version of high without overflow signals.
	// m_upper will be handled normally as soon as the out-most atomic
	// block is left unless Clear.clearOverflow is called in the interim.
	// This is all together the expected behavior.
	high = call MathUpper.inc( high );
	low = call CounterFrom.get();
      }
      {
	to_size_type high_to = call MathTo.cast_to( call MathUpper.cast_from( high ) );
	to_size_type low_to = call MathTo.cast_to( call MathFrom.cast_from( low ) );
	rv = call MathTo.or( call MathTo.sl( high_to, sizeof(from_size_type)*8 ), low_to );
      }
    }
    return rv;
  }

  // isOverflowPending only makes sense when it's already part of a larger
  // async block, so there's no async inside the command itself, where it
  // wouldn't do anything useful.

  async command bool Counter.isOverflowPending()
  {
    return call MathUpper.eq( m_upper, call MathUpper.cast_to(-1) )
	   && call CounterFrom.isOverflowPending();
  }

  // clearOverflow also only makes sense inside a larger atomic block, but we
  // include the inner atomic block to ensure consistent internal state just in
  // case someone calls it non-atomically.

  async command void Counter.clearOverflow()
  {
    atomic
    {
      if( call Counter.isOverflowPending() )
      {
	m_upper = call MathUpper.inc(m_upper);
	call CounterFrom.clearOverflow();
      }
    }
  }

  async event void CounterFrom.overflow()
  {
    atomic
    {
      m_upper = call MathUpper.inc(m_upper);
      if( call MathUpper.eq( m_upper, call MathUpper.cast_to(0) ) )
	signal Counter.overflow();
    }
  }
}

