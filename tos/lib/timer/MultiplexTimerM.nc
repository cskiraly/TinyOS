//$Id: MultiplexTimerM.nc,v 1.1.2.1 2005-03-30 17:54:53 cssharp Exp $

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

// This is a generic multiplexer component that takes an alarm and makes a
// timer.

generic module MultiplexTimerM(
  typedef frequency_tag,
  typedef size_type,
  int max_timers )
{
  provides interface Init;
  provides interface TimerAsyncBase<frequency_tag,size_type> as TimerAsyncBase[ uint8_t num ];
  uses interface AlarmBase<frequency_tag,size_type> as AlarmFrom;
  uses interface MathOps<size_type> as Math;
}
implementation
{
  enum
  {
    NUM_TIMERS = max_timers,
    END_OF_LIST = 255,
  };

  typedef struct
  {
    size_type t0;
    size_type dt;
  } Timer_t;

  typedef struct
  {
    uint8_t next;
    bool isperiodic : 1;
    bool isrunning : 1;
    bool isqueued : 1;
    bool _reserved : 5;
  } Flags_t;

  Timer_t m_timers[NUM_TIMERS];
  Flags_t m_flags[NUM_TIMERS];
  uint8_t m_head;
  bool m_processing_timers;
  bool m_reprocess_timers;


  command error_t Init.init()
  {
    atomic
    {
      bzero( m_timers, sizeof(m_timers) );
      bzero( m_flags, sizeof(m_flags) );
      m_head = END_OF_LIST;
      m_processing_timers = FALSE;
      m_reprocess_timers = FALSE;
    }
    return SUCCESS;
  }

  void insertTimer( uint8_t num )
  {
    if( !m_flags[num].isqueued )
    {
      m_flags[num].next = m_head;
      m_head = num;
      m_flags[num].isqueued = TRUE;
    }
    m_flags[num].isrunning = TRUE;
  }

  void expungeStoppedTimers()
  {
    uint8_t prev = END_OF_LIST;
    uint8_t num = m_head;
    while( num != END_OF_LIST )
    {
      if( !m_flags[num].isrunning )
      {
	if( prev == END_OF_LIST )
	  m_head = m_flags[num].next;
	else
	  m_flags[prev].next = m_flags[num].next;

	m_flags[num].isqueued = FALSE;
      }
      else
      {
	prev = num;
      }
      num = m_flags[num].next;
    }
  }

  // I need to go through and comment this function.  It's important, subtle,
  // etc and no changes should be made to it without first understanding the
  // intent of each piece of it.
  void executeTimers( size_type then )
  {
    size_type min_remaining;
    size_type elapsed_last_exec;

    if( m_processing_timers )
    {
      m_reprocess_timers = TRUE;
      return;
    }

    m_processing_timers = TRUE;
    m_reprocess_timers = TRUE;
    while( m_reprocess_timers )
    {
      uint8_t num = m_head;

      min_remaining = call Math.castFromI8(-1);
      m_reprocess_timers = FALSE;

      while( num != END_OF_LIST )
      {
	Flags_t* flags = &m_flags[num];
	if( flags->isrunning )
	{
	  Timer_t* timer = &m_timers[num];
	  size_type elapsed_timer = call Math.sub( then, timer->t0 );

	  if( call Math.le( timer->dt, elapsed_timer ) )
	  {
	    if( flags->isperiodic )
	    {
	      size_type numMissed = call Math.castFromI8(-1);
	      while( call Math.le( timer->dt, elapsed_timer ) )
	      {
		timer->t0 = call Math.add( timer->t0, timer->dt );
		elapsed_timer = call Math.sub( elapsed_timer, timer->dt );
		numMissed = call Math.inc( numMissed );
		// XXX FIXME XXX do a real divide for large numMissed
	      }

	      signal TimerAsyncBase.fired[num]( timer->t0, numMissed );

	      {
		size_type remaining = call Math.sub( timer->dt, elapsed_timer );
		if( call Math.lt( remaining, min_remaining ) )
		  min_remaining = remaining;
	      }
	    }
	    else
	    {
	      flags->isrunning = FALSE;
	      signal TimerAsyncBase.fired[num]( timer->t0, call Math.castFromU8(0) );
	    }
	  }
	  else
	  {
	    size_type remaining = call Math.sub( timer->dt, elapsed_timer );
	    if( call Math.lt( remaining, min_remaining ) )
	      min_remaining = remaining;
	  }
	}
	
	num = flags->next;
      }

      {
	size_type prev_then = then;
	then = call AlarmFrom.now();
	elapsed_last_exec = call Math.sub( then, prev_then );
	m_reprocess_timers |= call Math.le( min_remaining, elapsed_last_exec );
      }
    }

    if( m_head != END_OF_LIST )
      call AlarmFrom.set( then, call Math.sub( min_remaining, elapsed_last_exec ) );

    expungeStoppedTimers();
    m_processing_timers = FALSE;
  }
  

  async event void AlarmFrom.fired()
  {
    atomic { executeTimers( call AlarmFrom.get() ); }
  }

  void startTimer( uint8_t num, size_type t0, size_type dt, bool isperiodic )
  {
    atomic
    {
      Timer_t* timer = &m_timers[num];
      Flags_t* flags = &m_flags[num];
      timer->t0 = t0;
      timer->dt = dt;
      flags->isperiodic = isperiodic;
      insertTimer( num );
      executeTimers( call AlarmFrom.now() );
    }
  }

  async command void TimerAsyncBase.startPeriodicNow[ uint8_t num ]( size_type dt )
  {
    return startTimer( num, call AlarmFrom.now(), dt, TRUE );
  }

  async command void TimerAsyncBase.startOneShotNow[ uint8_t num ]( size_type dt )
  {
    return startTimer( num, call AlarmFrom.now(), dt, FALSE );
  }

  async command void TimerAsyncBase.stop[ uint8_t num ]()
  {
    atomic { m_flags[num].isrunning = FALSE; }
  }


  async command bool TimerAsyncBase.isRunning[ uint8_t num ]()
  {
    bool rv;
    atomic { rv = m_flags[num].isrunning; }
    return rv;
  }

  async command bool TimerAsyncBase.isOneShot[ uint8_t num ]()
  {
    bool rv;
    atomic { rv = !m_flags[num].isperiodic; }
    return rv;
  }

  async command void TimerAsyncBase.startPeriodic[ uint8_t num ]( size_type t0, size_type dt )
  {
    return startTimer( num, t0, dt, TRUE );
  }

  async command void TimerAsyncBase.startOneShot[ uint8_t num ]( size_type t0, size_type dt )
  {
    return startTimer( num, t0, dt, FALSE );
  }

  async command size_type TimerAsyncBase.getNow[ uint8_t num ]()
  {
    return call AlarmFrom.now();
  }

  async command size_type TimerAsyncBase.gett0[ uint8_t num ]()
  {
    size_type rv;
    atomic { rv = m_timers[num].t0; }
    return rv;
  }

  async command size_type TimerAsyncBase.getdt[ uint8_t num ]()
  {
    size_type rv;
    atomic { rv = m_timers[num].dt; }
    return rv;
  }

  default async event void TimerAsyncBase.fired[ uint8_t num ]( size_type when, size_type numMissed )
  {
  }
}

