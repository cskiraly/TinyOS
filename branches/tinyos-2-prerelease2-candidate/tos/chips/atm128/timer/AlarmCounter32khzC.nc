/// $Id: AlarmCounter32khzC.nc,v 1.1.2.1 2005-10-27 20:31:27 idgay Exp $

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
/// @author David Gay <dgay@intel-research.net>

// Glue hardware timers into Alarm32khzC.
configuration AlarmCounter32khzC
{
  provides interface Init;
  provides interface Alarm<T32khz,uint32_t> as Alarm32khz32;
  provides interface Counter<T32khz,uint32_t> as Counter32khz32;
  provides interface LocalTime<T32khz> as LocalTime32khz;
}
implementation
{
  components HplTimer0C,
    new Atm128AlarmC(T32khz, uint8_t, ATM128_CLK8_NORMAL, 2) as HalAlarm,
    new Atm128CounterC(T32khz, uint8_t) as HalCounter, 
    new TransformAlarmCounterC(T32khz, uint32_t, T32khz, uint8_t, 0, uint32_t) 
      as Transform32,
    new CounterToLocalTimeC(T32khz)
    ;

  // Top-level interface wiring
  Alarm32khz32 = Transform32;
  Counter32khz32 = Transform32;
  LocalTime32khz = CounterToLocalTimeC;

  // Strap in low-level hardware timer (Timer0)
  Init = HalAlarm;
  HalAlarm.HplTimer -> HplTimer0C.Timer0;
  HalAlarm.HplCompare -> HplTimer0C.Compare0;
  HalCounter.Timer -> HplTimer0C.Timer0;

  // Alarm Transform Wiring
  Transform32.AlarmFrom -> HalAlarm;
  Transform32.CounterFrom -> HalCounter;
  CounterToLocalTimeC.Counter -> Transform32;
}
