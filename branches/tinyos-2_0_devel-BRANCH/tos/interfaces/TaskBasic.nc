// $Id: TaskBasic.nc,v 1.1.2.2 2005-01-20 20:06:18 scipio Exp $
/*									tab:4
 * "Copyright (c) 2004-5 The Regents of the University  of California.  
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
 * Copyright (c) 2004-5 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */

/**
  * The basic TinyOS task interface, as discussed in TEP 106.
  *
  * @author Philip Levis
  * @date   January 12, 2005
  */ 


includes TinyError;

interface TaskBasic {

  /**
   * Post this task to the TinyOS scheduler. At some later time,
   * depending on the scheduling policy, the scheduler will signal the
   * <tt>run()</tt> event. SUCCESS means the task was successfuly
   * posted; the semantics of a non-SUCCESS return value depend on the
   * implementation of this interface (the class of task).
   */
  
  async command error_t post();

  /**
   * Event from the scheduler to run this task. Following the TinyOS
   * concurrency model, the codes invoked from <tt>run()</tt> signals
   * execute atomically with respect to one another, but can be
   * preempted by async commands/events.
   */
  event void run();
}
