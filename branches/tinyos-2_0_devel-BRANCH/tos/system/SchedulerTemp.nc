// $Id: SchedulerTemp.nc,v 1.1.2.1 2005-03-09 23:07:31 scipio Exp $

/*									tab:4
 * "Copyright (c) 2000-2003 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
/*
 *
 * Authors:		Philip Levis
 * Date last modified:  $Id: SchedulerTemp.nc,v 1.1.2.1 2005-03-09 23:07:31 scipio Exp $
 *
 */

/**
 * SchedulerTemp is a scheduler to be temporarily backwards compatible
 * with TinyOS 1.x tasks, until nesC has full Scheduler/Task support.
 *
 * @author Philip Levis
 * @date   March 9 2005
 */


module SchedulerTemp {
  provides interface Scheduler;
  provides interface TaskBasic[uint8_t id];
}
implementation {
  enum {
    NUM_TASKS = uniqueCount("TinyScheduler$TaskBasic"),
    END_TASK = 255,
#ifdef TOSH_MAX_TASKS_LOG2
#if TOSH_MAX_TASKS_LOG2 > 8
#error "Maximum of 256 tasks, TOSH_MAX_TASKS_LOG2 must be <= 8"
#endif
    TOSH_MAX_TASKS = 1 << TOSH_MAX_TASKS_LOG2,
#else
    TOSH_MAX_TASKS = 32,
#endif
    TOSH_TASK_BITMASK = (TOSH_MAX_TASKS - 1)
  };
  
  typedef struct {
    void (*tp) ();
  } TOSH_sched_entry_t;

  
  uint8_t m_head;
  uint8_t m_tail;
  uint8_t m_next[NUM_TASKS];

  uint8_t TOSH_sched_full;
  volatile uint8_t TOSH_sched_free;
  TOSH_sched_entry_t TOSH_queue[TOSH_MAX_TASKS];
      
  // move the head forward
  // if the head is at the end, mark the tail at the end, too
  // mark the task as not in the queue
  uint8_t popTask() {
    atomic {
      if (m_head != END_TASK) {
	uint8_t id = m_head;
	m_head = m_next[m_head];
	if (m_head == END_TASK) {
	  m_tail = END_TASK;
	}
	m_next[id] = END_TASK;
	return id;
      }
      else {
	return END_TASK;
      }
    }
  }
  
  bool isWaiting(uint8_t id) {
    atomic {
      return (m_next[id] != END_TASK) || (m_tail == id);
    }
  }

  bool pushTask( uint8_t id ) {
    atomic {
      if (!isWaiting(id)) {
	if (m_head == END_TASK) {
	  m_head = id;
	  m_tail = id;
	}
	else {
	  m_next[m_tail] = id;
	  m_tail = id;
	}
	return TRUE;
      }
      else {
	return FALSE;
      }
    }
  }

  bool TOSH_run_next_task();
  
  
  command void Scheduler.init()
  {
    atomic
    {
      uint8_t* ii;
      uint8_t i;
      TOSH_sched_free = 0;
      TOSH_sched_full = 0;
      for (i = 0; i < TOSH_MAX_TASKS; i++)
	TOSH_queue[i].tp = 0;

      for( ii = m_next; ii != m_next+NUM_TASKS; ii++ ) {
	*ii = END_TASK;
      }
      m_head = END_TASK;
      m_tail = END_TASK;
      
    }
  }
  
  command bool Scheduler.runNextTask(bool sleep)
  {
    __nesc_atomic_t fInterruptFlags;
    uint8_t nextTask = END_TASK;
    
    if (sleep)
    {
      fInterruptFlags = __nesc_atomic_start();
      while (nextTask == END_TASK)
      {
	nextTask = popTask();
	if (nextTask == END_TASK)
	{
	  while (TOSH_run_next_task()) {}
	  __nesc_atomic_sleep();
	}
	else
	{
	  __nesc_atomic_end(fInterruptFlags);
	  signal TaskBasic.run[nextTask]();
	}
      }
      return TRUE;
    }
    else
    {
      fInterruptFlags = __nesc_atomic_start();
      nextTask = popTask();
      if (nextTask == END_TASK)
      {
	__nesc_atomic_end(fInterruptFlags);
	return FALSE;
      }
      else
      {
	__nesc_atomic_end(fInterruptFlags);
	signal TaskBasic.run[nextTask]();
	return TRUE;
      }
    }
  }

  /**
   * Return SUCCESS if the post succeeded, EBUSY if it was already posted.
   */
  
  async command error_t TaskBasic.post_[uint8_t id]()
  {
    __nesc_atomic_t fInterruptFlags;

    fInterruptFlags = __nesc_atomic_start();
    if (pushTask(id))
    {
      __nesc_atomic_end(fInterruptFlags);
      return SUCCESS;
    }
    else
    {
      __nesc_atomic_end(fInterruptFlags);
      return EBUSY;
    }
  }

  default event void TaskBasic.run[uint8_t id]()
  {
  }

  
  /* Backwards compatible code. */
  
  bool TOS_post(void (*tp) ()) __attribute__((C,spontaneous)) {
    uint8_t tmp;
    uint8_t start;
    bool more;
    
    atomic {
      start = TOSH_sched_full;
      tmp = start;
    }
    more = TRUE;
    while (more) {
      atomic {
	if (TOSH_queue[tmp].tp == tp) {
	  return 0;
	}
      }
      
      tmp = (tmp + 1) & TOSH_TASK_BITMASK;
      atomic {
	if (tmp == TOSH_sched_free) {
	  more = FALSE;
	}
      }
    }
    
    atomic {
      tmp = TOSH_sched_free;
      if (TOSH_queue[tmp].tp == 0) {
	TOSH_sched_free = (tmp + 1) & TOSH_TASK_BITMASK;
	TOSH_queue[tmp].tp = tp;
	return TRUE;
      }
      else {
	return FALSE;
      }
    }
  }

  bool TOSH_run_next_task ()  {
    uint8_t old_full;
    void (*func)();
    
    atomic {
      old_full = TOSH_sched_full;
      func = TOSH_queue[old_full].tp;
      if (func == 0) {
	return 0;
      }
      
      TOSH_queue[old_full].tp = 0;
      TOSH_sched_full = (old_full + 1) & TOSH_TASK_BITMASK;
    }
    
    func();
    return 1;
  }

}

