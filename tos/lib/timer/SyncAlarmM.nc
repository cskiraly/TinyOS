//$Id: SyncAlarmM.nc,v 1.1.2.3 2005-04-16 06:19:13 cssharp Exp $

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

// Translate an interrupt context alarm event to task context.
// Note that the interface is still marked async.

includes Timer;

generic module SyncAlarmM( typedef frequency_tag, typedef size_type @integer() )
{
  provides interface AlarmBase<frequency_tag,size_type> as AlarmBase;
  uses interface AlarmBase<frequency_tag,size_type> as AlarmBaseFrom;
}
implementation
{
  async command size_type AlarmBase.now()
  {
    return call AlarmBaseFrom.now();
  }

  async command size_type AlarmBase.get()
  {
    return call AlarmBaseFrom.get();
  }

  async command bool AlarmBase.isSet()
  {
    return call AlarmBaseFrom.isSet();
  }

  async command void AlarmBase.cancel()
  {
    call AlarmBaseFrom.cancel();
  }

  async command void AlarmBase.set( size_type t0, size_type dt )
  {
    call AlarmBaseFrom.set( t0, dt );
  }

  task void fireAlarm()
  {
    signal AlarmBase.fired();
  }

  async event void AlarmBaseFrom.fired()
  {
    post fireAlarm();
  }
}

