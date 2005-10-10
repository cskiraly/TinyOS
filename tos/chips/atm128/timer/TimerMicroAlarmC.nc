/// $Id: TimerMicroAlarmC.nc,v 1.1.2.1 2005-10-10 00:19:09 mturon Exp $

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

// Glue hardware timers into AlarmMicroC.
configuration TimerMicroAlarmC
{
  provides interface Init;
  provides interface Alarm<TMicro,uint16_t> as AlarmMicro16;
  provides interface Alarm<TMicro,uint32_t> as AlarmMicro32;
}
implementation
{
  components HplTimerC,
    new Atm128AlarmP(TMicro, uint8_t, ATM128_CLK8_NORMAL) as HalAlarm,
    new TransformAlarmC(TMicro,uint16_t,TMicro,uint8_t,0) as Transform16,
    new TransformAlarmC(TMicro,uint32_t,TMicro,uint16_t,0) as Transform32,
    TimerMicroCounterC as Counter
    ;

  // Top-level interface wiring
  AlarmMicro16 = Transform16;
  AlarmMicro32 = Transform32;

  // Strap in low-level hardware timer (Timer0)
  Init = HalAlarm;
  HalAlarm.HplTimer -> HplTimerC.Timer3;      // assign HW resource : TIMER3
  HalAlarm.HplCompare -> HplTimerC.Compare3A; // assign HW resource : COMPARE3

  // Alarm Transform Wiring
  Transform16.AlarmFrom -> HalAlarm;      // start with 16-bit hardware alarm
  Transform16.Counter -> Counter;         // uses 16-bit virtualized counter
  Transform32.AlarmFrom -> Transform16;   // then feed that into 32-bit xform
  Transform32.Counter -> Counter;         // uses 32-bit virtualized counter
}

