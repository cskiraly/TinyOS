//$Id: SyncAlarmC.nc,v 1.1.2.3 2005-04-16 06:19:13 cssharp Exp $

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

// SyncAlarmC takes an alarm and filters its fired event through a task, thus
// transforming it from interrupt context to task context.  It's used to
// sychronize an alarm feeding into MultiplexTimerM to get sync timers out
// instead of async timers.

includes Timer;

generic configuration SyncAlarmC( typedef frequency_tag, typedef size_type @integer() )
{
  provides interface AlarmBase<frequency_tag,size_type> as AlarmBase;
  uses interface AlarmBase<frequency_tag,size_type> as AlarmBaseFrom;
}
implementation
{
  components new SyncAlarmM(frequency_tag,size_type) as SyncAlarm
	   ;

  AlarmBase = SyncAlarm;
  AlarmBaseFrom = SyncAlarm;
}

