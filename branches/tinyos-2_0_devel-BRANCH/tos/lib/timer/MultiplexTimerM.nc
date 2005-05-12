//$Id: MultiplexTimerM.nc,v 1.1.2.6 2005-05-12 22:46:41 cssharp Exp $

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
  typedef size_type @integer(),
  int max_timers )
{
  provides interface Init;
  provides interface TimerAsyncBase<frequency_tag,size_type> as TimerAsyncBase[ uint8_t num ];
  uses interface AlarmBase<frequency_tag,size_type> as AlarmFrom;
}
implementation
{
  enum
  {
    NUM_TIMERS = max_timers,
    END_OF_LIST = 255,
    SIGN_BIT = ((size_type)1) << (8 * sizeof(size_type) - 1),
  };

  typedef struct
  {
    size_type t0;
    size_type dt;
  } Timer_t;

  typedef struct
  {
    bool isperiodic : 1;
    bool isrunning : 1;
    bool _reserved : 6;
  } Flags_t;

  Timer_t m_timers[NUM_TIMERS];
  Flags_t m_flags[NUM_TIMERS];
  bool m_processing_timers;
  bool m_reprocess_timers;

  command error_t Init.init()
  {
    atomic
    {
      memset(m_timers, 0, sizeof(m_timers));
      memset(m_flags, 0, sizeof(m_flags));
      m_processing_timers = FALSE;
      m_reprocess_timers = FALSE;
    }
    return SUCCESS;
  }

  void insertTimer( uint8_t num )
  {
    m_flags[num].isrunning = TRUE;
  }

  void executeTimers( size_type then )
  {
    size_type min_remaining = 0;
    bool min_remaining_isset = FALSE;
    bool reprocess_timers = TRUE;

    atomic
    {
      if( m_processing_timers )
      {
	m_reprocess_timers = TRUE;
	return;
      }
      m_processing_timers = TRUE;
      m_reprocess_timers = FALSE;
    }

    while( reprocess_timers )
    {
      int num;
      reprocess_timers = FALSE;
      min_remaining = 0;
      min_remaining = ~min_remaining;
      min_remaining_isset = FALSE;

      for( num=0; num<NUM_TIMERS; num++ )
      {
	Flags_t* flags;
	Timer_t* timer;
	bool fire_timer = FALSE;
	bool calculate_remaining = FALSE;
	size_type numMissed;
	size_type elapsed = 0;
	size_type t0;

	atomic
	{
	  flags = &m_flags[num];
	  timer = &m_timers[num];

	  if( flags->isrunning )
	  {
	    elapsed = then - timer->t0;
	    numMissed = 0;

	    if( (elapsed & SIGN_BIT) != 0 )
	    {
	      // if t0 is "in the future" then don't process it
	      // this means that
	      //   1) t0 in the future are okay
	      //   2) dt can be at most maxval(size_type)/2
	      calculate_remaining = TRUE;
	    }
	    else if( timer->dt <= elapsed )
	    {
	      if( flags->isperiodic )
	      {
		timer->t0 += timer->dt;
		elapsed -= timer->dt;

		if( timer->dt <= elapsed )
		{
		  size_type elapsed_rem = elapsed % timer->dt;
		  numMissed = elapsed / timer->dt;
		  timer->t0 += elapsed - elapsed_rem;
		  elapsed = elapsed_rem;
		}

		fire_timer = TRUE;
		calculate_remaining = TRUE;
	      }
	      else
	      {
		flags->isrunning = FALSE;
		fire_timer = TRUE;
	      }
	    }
	    else
	    {
	      calculate_remaining = TRUE;
	    }
	  }

	  if( calculate_remaining )
	  {
	    size_type remaining = timer->dt - elapsed;
	    if( remaining < min_remaining )
	      min_remaining = remaining;
	    min_remaining_isset = TRUE;
	  }

	  t0 = timer->t0;
	}

	if( fire_timer )
	  signal TimerAsyncBase.fired[num]( t0, numMissed );
      }

      atomic
      {
	size_type prev_then = then;
	size_type elapsed_last_exec;
	then = call AlarmFrom.getNow();
	elapsed_last_exec = then - prev_then;
	if( m_reprocess_timers )
	{
	  reprocess_timers = TRUE;
	  m_reprocess_timers = FALSE;
	}
	else if( min_remaining <= elapsed_last_exec )
	{
	  reprocess_timers = TRUE;
	}
	else
	{
	  m_processing_timers = FALSE;
	  reprocess_timers = FALSE;
	  if( min_remaining_isset )
	    call AlarmFrom.start( then, min_remaining - elapsed_last_exec );
	}
      }
    }
  }
  

  async event void AlarmFrom.fired()
  {
    executeTimers( call AlarmFrom.getAlarm() );
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
    }
    executeTimers( call AlarmFrom.getNow() );
  }

  async command void TimerAsyncBase.startPeriodicNow[ uint8_t num ]( size_type dt )
  {
    return startTimer( num, call AlarmFrom.getNow(), dt, TRUE );
  }

  async command void TimerAsyncBase.startOneShotNow[ uint8_t num ]( size_type dt )
  {
    return startTimer( num, call AlarmFrom.getNow(), dt, FALSE );
  }

  async command void TimerAsyncBase.stop[ uint8_t num ]()
  {
    atomic { m_flags[num].isrunning = FALSE; }
  }


  async command bool TimerAsyncBase.isRunning[ uint8_t num ]()
  {
    atomic { return m_flags[num].isrunning; }
  }

  async command bool TimerAsyncBase.isOneShot[ uint8_t num ]()
  {
    atomic { return !m_flags[num].isperiodic; }
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
    return call AlarmFrom.getNow();
  }

  async command size_type TimerAsyncBase.gett0[ uint8_t num ]()
  {
    atomic { return m_timers[num].t0; }
  }

  async command size_type TimerAsyncBase.getdt[ uint8_t num ]()
  {
    atomic { return m_timers[num].dt; }
  }

  default async event void TimerAsyncBase.fired[ uint8_t num ]( size_type when, size_type numMissed )
  {
  }
}

