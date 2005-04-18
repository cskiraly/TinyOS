/// $Id: TimerMilliAlarmC.nc,v 1.1.2.2 2005-04-18 08:18:31 mturon Exp $

/**
 * Copyright (c) 2004-2005 Crossbow Technology, Inc.  All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL CROSSBOW TECHNOLOGY OR ANY OF ITS LICENSORS BE LIABLE TO 
 * ANY PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL 
 * DAMAGES ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN
 * IF CROSSBOW OR ITS LICENSOR HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH 
 * DAMAGE. 
 *
 * CROSSBOW TECHNOLOGY AND ITS LICENSORS SPECIFICALLY DISCLAIM ALL WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY 
 * AND FITNESS FOR A PARTICULAR PURPOSE. THE SOFTWARE PROVIDED HEREUNDER IS 
 * ON AN "AS IS" BASIS, AND NEITHER CROSSBOW NOR ANY LICENSOR HAS ANY 
 * OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR 
 * MODIFICATIONS.
 */

/// @author Martin Turon <mturon@xbow.com>

// Glue hardware timers into TimerMilliC.
configuration TimerMilliAlarmC
{
  provides interface Init;
  provides interface Alarm<TMilli> as TimerMilliAlarm;
  provides interface AlarmBase<TMilli,uint32_t> as TimerMilliBase;
}
implementation
{
  components HPLTimerM,
      new HALAlarmM(T32khz,uint8_t) as HALAlarm,
      new TransformAlarmM(TMilli,uint32_t,T32khz,uint8_t,0) as Transform,
      new CastAlarmM(TMilli) as Cast,
      TimerMilliCounterC as Counter
      ;

  TimerMilliAlarm = Cast;
  TimerMilliBase = Transform;

  // Alarm Transform Wiring
  Cast.AlarmFrom -> Transform;
  Transform.AlarmFrom -> HALAlarm;
  Transform.Counter -> Counter;

  // Strap in low-level hardware timer (Timer0)
  Init = HALAlarm;
  HALAlarm.HPLTimer -> HPLTimerM.Timer0;
  HALAlarm.HPLCompare -> HPLTimerM.Compare0;
}

