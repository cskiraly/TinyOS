// $Id: SchedulerBasic.nc,v 1.1.2.1 2005-01-20 04:58:55 scipio Exp $

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
 * Date last modified:  $Id: SchedulerBasic.nc,v 1.1.2.1 2005-01-20 04:58:55 scipio Exp $
 *
 */

/**
 * SchedulerBasic implements the default TinyOS scheduler sequence, as
 * documented in TEP 106.
 *
 * @author Philip Levis
 * @date   January 19 2005
 */


module SchedulerBasic {
  provides interface Scheduler;
  provides interface TaskBasic[uint8_t id];
}
implementation {
  enum {
    NUM_TASKS = uniqueCount("TaskBasic"),
    END_TASK = 255,
  };

  uint8_t m_head;
  uint8_t m_tail;
  uint8_t m_next[NUM_TASKS];

  void flushTasks() {
    uint8_t* ii;
    for( ii = m_next; ii != m_next+NUM_TASKS; ii++ ) {
      *ii = END_TASK;
    }
    m_head = END_TASK;
    m_tail = END_TASK;
  }
  
  command void Scheduler.init() {
    atomic {
      uint8_t* ii;
      for( ii = m_next; ii != m_next+NUM_TASKS; ii++ ) {
	*ii = END_TASK;
      }
      m_head = END_TASK;
      m_tail = END_TASK;
    }
  }

  command bool Scheduler.runNextTask(bool sleep) {
    if (sleep) {
      
    }
    else {

    }
  }

  command error_t TaskBasic.post[uint8_t id]() {
    
  }

}
