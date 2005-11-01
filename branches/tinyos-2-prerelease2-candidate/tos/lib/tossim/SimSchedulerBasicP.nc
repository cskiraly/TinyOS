// $Id: SimSchedulerBasicP.nc,v 1.1.2.1 2005-08-19 01:06:58 scipio Exp $

/*									tab:4
 * "Copyright (c) 2000-2005 The Regents of the University  of California.  
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
 * Copyright (c) 2002-2005 Intel Corporation
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
 * Date last modified:  $Id: SimSchedulerBasicP.nc,v 1.1.2.1 2005-08-19 01:06:58 scipio Exp $
 *
 */

/**
 * SimSchedulerBasic implements the default TinyOS scheduler sequence
 * (documented in TEP 106) for the TOSSIM platform. Its major departure
 * from the standard TinyOS scheduler is that tasks are executed
 * within TOSSIM events.
 *
 * @author Philip Levis
 * @author Cory Sharp
 * @date   August 19 2005
 */


#include <sim_event_queue.h>

module SimSchedulerBasicP {
  provides interface Scheduler;
  provides interface TaskBasic[uint8_t id];
}
implementation
{
  enum
  {
    NUM_TASKS = uniqueCount("TinySchedulerC.TaskBasic"),
    NO_TASK = 255,
  };

  uint8_t m_head;
  uint8_t m_tail;
  uint8_t m_next[NUM_TASKS];

  /* This simulation state is kept on a per-node basis.
     Better to take advantage of nesC's automatic state replication
     than try to do it ourselves. */
  bool sim_scheduler_event_pending = FALSE;
  sim_event_t sim_scheduler_event;

  int sim_config_task_latency() {return 100;}
  

  /* Only enqueue the event for execution if it is
     not already enqueued. If there are more tasks in the
     queue, the event will re-enqueue itself (see the handle
     function). */
  
  void sim_scheduler_submit_event() {
    if (sim_scheduler_event_pending == FALSE) {
      sim_scheduler_event.time = sim_time() + sim_config_task_latency();
      sim_queue_insert(&sim_scheduler_event);
      sim_scheduler_event_pending = TRUE;
    }
  }

  void sim_scheduler_event_handle(sim_event_t* e) {
    sim_scheduler_event_pending = FALSE;

    // If we successfully executed a task, re-enqueue the event. This
    // will always succeed, as sim_scheduler_event_pending was just
    // set to be false.  Note that this means there will be an extra
    // execution (on an empty task queue). We could optimize this
    // away, but this code is cleaner, and more accurately reflects
    // the real TinyOS main loop.
    
    if (call Scheduler.runNextTask(FALSE)) {
      sim_scheduler_submit_event();
    }
  }

  
  /* Initialize a scheduler event. This should only be done
   * once, when the scheduler is initialized. */
  void sim_scheduler_event_init(sim_event_t* e) {
    e->mote = sim_node();
    e->force = 0;
    e->data = NULL;
    e->handle = sim_scheduler_event_handle;
    e->cleanup = sim_queue_cleanup_none;
  }



  // Helper functions (internal functions) intentionally do not have atomic
  // sections.  It is left as the duty of the exported interface functions to
  // manage atomicity to minimize chances for binary code bloat.

  // move the head forward
  // if the head is at the end, mark the tail at the end, too
  // mark the task as not in the queue
  uint8_t popTask()
  {
    if( m_head != NO_TASK )
    {
      uint8_t id = m_head;
      m_head = m_next[m_head];
      if( m_head == NO_TASK )
      {
	m_tail = NO_TASK;
      }
      m_next[id] = NO_TASK;
      return id;
    }
    else
    {
      return NO_TASK;
    }
  }
  
  bool isWaiting( uint8_t id )
  {
    return (m_next[id] != NO_TASK) || (m_tail == id);
  }

  bool pushTask( uint8_t id )
  {
    if( !isWaiting(id) )
    {
      if( m_head == NO_TASK )
      {
	m_head = id;
	m_tail = id;
      }
      else
      {
	m_next[m_tail] = id;
	m_tail = id;
      }
      return TRUE;
    }
    else
    {
      return FALSE;
    }
  }
  
  command void Scheduler.init()
  {
    atomic
    {
      memset( m_next, NO_TASK, sizeof(m_next) );
      m_head = NO_TASK;
      m_tail = NO_TASK;

      sim_scheduler_event_pending = FALSE;
      sim_scheduler_event_init(&sim_scheduler_event);
    }
  }
  
  command bool Scheduler.runNextTask( bool sleep )
  {
    uint8_t nextTask;
    atomic
    {
      nextTask = popTask();
      if( nextTask == NO_TASK )
      {
	if( sleep ) {
	  // do nothing
	}
	return FALSE;
      }
    }
    signal TaskBasic.runTask[nextTask]();
    return TRUE;
  }

  /**
   * Return SUCCESS if the post succeeded, EBUSY if it was already posted.
   */
  
  async command error_t TaskBasic.postTask[uint8_t id]()
  {
    error_t result;
    atomic {
      result =  pushTask(id) ? SUCCESS : EBUSY;
    }
    if (result == SUCCESS) {
      sim_scheduler_submit_event();
    }
  }

  default event void TaskBasic.runTask[uint8_t id]()
  {
  }



}

