// $Id: SchedulerBasic.nc,v 1.1.2.8 2005-04-17 08:58:38 cssharp Exp $

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
 * Date last modified:  $Id: SchedulerBasic.nc,v 1.1.2.8 2005-04-17 08:58:38 cssharp Exp $
 *
 */

/**
 * SchedulerBasic implements the default TinyOS scheduler sequence, as
 * documented in TEP 106.
 *
 * @author Philip Levis
 * @author Cory Sharp
 * @date   January 19 2005
 */

includes hardware;

module SchedulerBasic
{
  provides interface Scheduler;
  provides interface TaskBasic[uint8_t id];
}
implementation
{
  enum
  {
    NUM_TASKS = uniqueCount("TinyScheduler.TaskBasic"),
    END_TASK = 255,
  };

  uint8_t m_head;
  uint8_t m_tail;
  uint8_t m_next[NUM_TASKS];

  // Helper functions (internal functions) intentionally do not have atomic
  // sections.  It is left as the duty of the exported interface functions to
  // manage atomicity to minimize chances for binary code bloat.

  // move the head forward
  // if the head is at the end, mark the tail at the end, too
  // mark the task as not in the queue
  uint8_t popTask()
  {
    if( m_head != END_TASK )
    {
      uint8_t id = m_head;
      m_head = m_next[m_head];
      if( m_head == END_TASK )
      {
	m_tail = END_TASK;
      }
      m_next[id] = END_TASK;
      return id;
    }
    else
    {
      return END_TASK;
    }
  }
  
  bool isWaiting( uint8_t id )
  {
    return (m_next[id] != END_TASK) || (m_tail == id);
  }

  bool pushTask( uint8_t id )
  {
    if( !isWaiting(id) )
    {
      if( m_head == END_TASK )
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
      memset( m_next, END_TASK, sizeof(m_next) );
      m_head = END_TASK;
      m_tail = END_TASK;
    }
  }
  
  command bool Scheduler.runNextTask( bool sleep )
  {
    uint8_t nextTask;
    atomic
    {
      nextTask = popTask();
      if( nextTask == END_TASK )
      {
	if( sleep )
	  __nesc_atomic_sleep();
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
    atomic { return pushTask(id) ? SUCCESS : EBUSY; }
  }

  default event void TaskBasic.runTask[uint8_t id]()
  {
  }
}

