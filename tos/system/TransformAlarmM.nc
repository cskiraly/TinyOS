//$Id: TransformAlarmM.nc,v 1.1.2.1 2005-02-26 02:27:15 cssharp Exp $

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
  typedef to_size_type,
  typedef from_frequency_tag,
  typedef from_size_type,
  uint8_t bit_shift_right )
{
  provides interface AlarmBase<to_size_type,to_frequency_tag> as Alarm;
  uses interface CounterBase<to_size_type,to_frequency_tag> as Counter;
  uses interface AlarmBase<from_size_type,from_frequency_tag> as AlarmFrom;
  uses interface MathOps<to_size_type> as MathTo;
  uses interface MathOps<from_size_type> as MathFrom;
  uses interface CastOps<from_size_type,to_size_type> as CastFromTo;
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
    return call MathTo.add( m_t0, m_dt );
  }

  async command bool Alarm.isSet()
  {
    return call AlarmFrom.isSet();
  }

  async command void Alarm.cancel()
  {
    call AlarmFrom.cancel();
  }

  /*
    Why anchored relative alarms (t0,dt) instead of assuming absolute alarms
    (0,t) or unanchored relative alarms (dt)?

    Absolute alarms (0,t) assume the boundedness of an alarm/counter is
    insignificant.  If the counter range is [0,T], then there is a race
    condition with the free running counter as the alarm time t approaches the
    maximum value T.  The specified alarm time t may have to wait until the
    counter rolls around to the next t, causing the alarm to fire T too late.

    Even though this problem is more significant for fast-overflow alarms at
    the hardware level, it exists for slow-overflow alarms at higher
    abstraction levels.  A wider absolute timer derived from a thinner absolute
    timer suffers from all race occurences on the thinner timer.  This means
    absolute time is not suitable for anything other than the highest level
    abstraction.  The highest abstraction of course still suffers from the race
    condition, and the absolute delay before a race occurs makes it that much
    more difficult to identify and debug odd behaviors.
    
    Unanchored relative alarms (dt) have race conditions only for small dt,
    which can be accounted for.  But, they make it difficult account for
    computational slop from when the relative delay is calculated to when the
    alarm is set.  This affects alarms based on high frequency counters more
    than low frequency counters.  Periodic alarms can externally track their
    firing times relative to the free running counter, meaning this slop only
    induces alarm jitter and not frequency skew.

    Anchored relatve alarms (t0,dt) have no computational slop and have less
    significant race conditions.  t0 is assumed to be in the past, and dt is
    delay from it.  A race occurs if the now-t0 approaches T, so alarms should
    be set with t0 in the recent past with any far past calculations done
    external to the alarm.

    An alarm may enforce a minimum delay to ensure atomicity in the calling
    functions, even for alarm times t0+dt in the past.

    Well, shit, there's going to be unspecified slop anyway from when the alarm
    event is fired to when the handler is invoked.  Is additional slop in the
    setting of the alarm significant?  If precise timing is required, it seems
    like the total slop must be calibrated in any case.  Does (t0,dt) buy
    anything?  I think so, because otherwise that slop is additive as alarms
    are derived from other alarms.  Basically, I tried writing set_alarm
    without t0 and dt, and it seemed hard/impossible to do right.  Show me if
    I'm wrong?  Thanks.

  */

  void set_alarm()
  {
    to_size_type now = call Counter.get();
    from_size_type now_from = call MathFrom.sl( call CastFromTo.left( now ), bit_shift_right );
    to_size_type elapsed = call MathTo.sub(now,m_t0);
    if( call MathTo.ge(elapsed,m_dt) )
    {
      m_t0 = call MathTo.add(m_t0,m_dt);
      m_dt = call MathTo.castFromU8(0);
      call AlarmFrom.set( now_from, call MathFrom.castFromU8(0) );
    }
    else
    {
      to_size_type remaining = call MathTo.sub( m_dt, elapsed );
      from_size_type remaining_from = call CastFromTo.left( remaining );
      to_size_type delay = call MathTo.castFromU32( ((uint32_t)1) << (8*sizeof(from_size_type)-1-bit_shift_right) );
      if( call MathTo.gt( remaining, delay ) )
      {
	from_size_type delay_from = call CastFromTo.left( delay );
	m_t0 = call MathTo.add( m_t0, delay );
	m_dt = call MathTo.sub( m_dt, delay );
	call AlarmFrom.set( now_from, call MathFrom.sl( delay_from, bit_shift_right ) );
      }
      else
      {
	m_t0 = call MathTo.add( m_t0, m_dt );
	m_dt = call MathTo.castFromU8(0);
	call AlarmFrom.set( now_from, call MathFrom.sl( remaining_from, bit_shift_right ) );
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
      if( call MathTo.eq( m_dt, call MathTo.castFromU8(0) ) )
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

