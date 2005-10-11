/// $Id: Timer32khzAlarmC.nc,v 1.1.2.4 2005-10-11 22:14:49 idgay Exp $

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

// Glue hardware timers into Alarm32khzC.
configuration Timer32khzAlarmC
{
  provides interface Init;
  provides interface Alarm<T32khz,uint32_t> as Alarm32khz32;
}
implementation
{
  components HplTimer0C,
    new Atm128AlarmP(T32khz, uint8_t, ATM128_CLK8_NORMAL) as HalAlarm,
    new TransformAlarmC(T32khz,uint32_t,T32khz,uint8_t,0) as Transform32,
    Timer32khzCounterC as Counter
    ;

  // Top-level interface wiring
  Alarm32khz32 = Transform32;

  // Strap in low-level hardware timer (Timer0)
  Init = HalAlarm;
  HalAlarm.HplTimer -> HplTimer0C.Timer0;      // assign HW resource : TIMER0
  HalAlarm.HplCompare -> HplTimer0C.Compare0;  // assign HW resource : COMPARE0

  // Alarm Transform Wiring
  Transform32.AlarmFrom -> HalAlarm;      // start with 8-bit hardware alarm
  Transform32.Counter -> Counter;         // uses 32-bit virtualized counter
}

