//$Id: TransformCounterM.nc,v 1.1.2.1 2005-02-26 02:27:15 cssharp Exp $

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

generic module TransformCounterM(
  typedef to_frequency_tag,
  typedef to_size_type,
  typedef from_frequency_tag,
  typedef from_size_type,
  uint8_t bit_shift_right,
  typedef upper_count_type )
{
  provides interface CounterBase<to_size_type,to_frequency_tag> as Counter;
  uses interface CounterBase<from_size_type,from_frequency_tag> as CounterFrom;
  uses interface MathOps<to_size_type> as MathTo;
  uses interface MathOps<from_size_type> as MathFrom;
  uses interface MathOps<upper_count_type> as MathUpper;
  uses interface CastOps<from_size_type,to_size_type> as CastFromTo;
  uses interface CastOps<upper_count_type,to_size_type> as CastUpperTo;
}
implementation
{
  upper_count_type m_upper;

  enum
  {
    LOW_SHIFT_RIGHT = bit_shift_right,
    HIGH_SHIFT_LEFT = 8*sizeof(from_size_type) - LOW_SHIFT_RIGHT,
    NUM_UPPER_BITS = 8*sizeof(to_size_type) - 8*sizeof(from_size_type) + bit_shift_right,
  };

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
	to_size_type high_to = call CastUpperTo.right( high );
	to_size_type low_to = call CastFromTo.right( call MathFrom.sr( low, LOW_SHIFT_RIGHT ) );
	rv = call MathTo.or( call MathTo.sl( high_to, HIGH_SHIFT_LEFT ), low_to );
      }
    }
    return rv;
  }

  // isOverflowPending only makes sense when it's already part of a larger
  // async block, so there's no async inside the command itself, where it
  // wouldn't do anything useful.

  async command bool Counter.isOverflowPending()
  {
    const upper_count_type overflow_mask = call MathUpper.dec( call MathUpper.sl(
      call MathUpper.castFromU8(1), NUM_UPPER_BITS ) );
    return call MathUpper.eq( call MathUpper.and( m_upper, overflow_mask ), overflow_mask )
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
      if( call MathUpper.eq( m_upper, call MathUpper.castFromU8(0) ) )
	signal Counter.overflow();
    }
  }
}

