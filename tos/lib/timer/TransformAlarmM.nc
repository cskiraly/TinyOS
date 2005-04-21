//$Id: TransformAlarmM.nc,v 1.1.2.3 2005-04-21 08:29:40 cssharp Exp $

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

generic module TransformAlarmM( 
  typedef to_frequency_tag,
  typedef to_size_type @integer(),
  typedef from_frequency_tag,
  typedef from_size_type @integer(),
  uint8_t bit_shift_right )
{
  provides interface AlarmBase<to_frequency_tag,to_size_type> as Alarm;
  uses interface CounterBase<to_frequency_tag,to_size_type> as Counter;
  uses interface AlarmBase<from_frequency_tag,from_size_type> as AlarmFrom;
}
implementation
{
  to_size_type m_t0;
  to_size_type m_dt;

  async command to_size_type Alarm.now()
  {
    return call Counter.get();
  }

  async command to_size_type Alarm.get()
  {
    return m_t0 + m_dt;
  }

  async command bool Alarm.isSet()
  {
    return call AlarmFrom.isSet();
  }

  async command void Alarm.cancel()
  {
    call AlarmFrom.cancel();
  }

  void set_alarm()
  {
    to_size_type now = call Counter.get();
    from_size_type now_from = now << bit_shift_right;
    to_size_type elapsed = now - m_t0;
    if( elapsed >= m_dt )
    {
      m_t0 += m_dt;
      m_dt = 0;
      call AlarmFrom.set( now_from, 0 );
    }
    else
    {
      to_size_type remaining = m_dt - elapsed;
      from_size_type remaining_from = remaining;
      to_size_type delay = 1;
      delay <<= 8 * sizeof(from_size_type) - 1 - bit_shift_right;
      if( remaining > delay )
      {
	from_size_type delay_from = delay;
	m_t0 = now + delay;
	m_dt = remaining - delay;
	call AlarmFrom.set( now_from, delay_from << bit_shift_right );
      }
      else
      {
	m_t0 += m_dt;
	m_dt = 0;
	call AlarmFrom.set( now_from, remaining_from << bit_shift_right );
      }
    }
  }

  async command void Alarm.set( to_size_type t0, to_size_type dt )
  {
    atomic
    {
      m_t0 = t0;
      m_dt = dt;
      set_alarm();
    }
  }

  async event void AlarmFrom.fired()
  {
    atomic
    {
      if( m_dt == 0 )
      {
	signal Alarm.fired();
      }
      else
      {
	set_alarm();
      }
    }
  }

  async event void Counter.overflow()
  {
  }

  default async event void Alarm.fired()
  {
  }
}

