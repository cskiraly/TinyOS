//$Id: TransformCounterC.nc,v 1.1.2.3 2005-05-20 21:50:40 cssharp Exp $

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

// TransformCounterC increases the size and/or decreases the precision of an
// existing Counter.  bit_shift_right specifies the power of two to decrease
// the precision.  upper_count_type specifies the type to internally store the
// upper bits -- those needed above from_size_type after its shifter right to
// fill to_size_type.

generic module TransformCounterC(
  typedef to_precision_tag,
  typedef to_size_type @integer(),
  typedef from_precision_tag,
  typedef from_size_type @integer(),
  uint8_t bit_shift_right,
  typedef upper_count_type @integer() )
{
  provides interface Counter<to_precision_tag,to_size_type> as Counter;
  uses interface Counter<from_precision_tag,from_size_type> as CounterFrom;
}
implementation
{
  upper_count_type m_upper;

  enum
  {
    LOW_SHIFT_RIGHT = bit_shift_right,
    HIGH_SHIFT_LEFT = 8*sizeof(from_size_type) - LOW_SHIFT_RIGHT,
    NUM_UPPER_BITS = 8*sizeof(to_size_type) - 8*sizeof(from_size_type) + bit_shift_right,
    // hack to remove warning when NUM_UPPER_BITS == 8*sizeof(upper_count_type)
    NUB_HACK0 = NUM_UPPER_BITS / 2,
    NUB_HACK1 = NUM_UPPER_BITS - NUB_HACK0,
    OVERFLOW_MASK = ((((upper_count_type)1) << NUB_HACK0) << NUB_HACK1) - 1,
  };

  async command to_size_type Counter.get()
  {
    to_size_type rv = 0;
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
	high++;
	low = call CounterFrom.get();
      }
      {
	to_size_type high_to = high;
	to_size_type low_to = low >> LOW_SHIFT_RIGHT;
	rv = (high_to << HIGH_SHIFT_LEFT) | low_to;
      }
    }
    return rv;
  }

  // isOverflowPending only makes sense when it's already part of a larger
  // async block, so there's no async inside the command itself, where it
  // wouldn't do anything useful.

  async command bool Counter.isOverflowPending()
  {
    return ((m_upper & OVERFLOW_MASK) == OVERFLOW_MASK)
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
	m_upper++;
	call CounterFrom.clearOverflow();
      }
    }
  }

  async event void CounterFrom.overflow()
  {
    atomic
    {
      m_upper++;
      if( (m_upper & OVERFLOW_MASK) == 0 )
	signal Counter.overflow();
    }
  }
}

