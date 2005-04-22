//$Id: AlarmMilliC.nc,v 1.1.2.1 2005-04-22 06:08:40 cssharp Exp $

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

//@author Cory Sharp <cssharp@eecs.berkeley.edu>

// The TinyOS Timer interfaces are discussed in TEP 102.

// Alarm32khzC is the alarm for async 32khz alarms
generic configuration AlarmMilliC()
{
  provides interface Init;
  provides interface Alarm<TMilli> as AlarmMilli;
  provides interface AlarmBase<TMilli,uint32_t> as AlarmBaseMilli;
}
implementation
{
  components MSP430Timer32khzMapC as Map
           , new MSP430AlarmM(T32khz) as MSP430Alarm
           , new TransformAlarmM(TMilli,uint32_t,T32khz,uint16_t,5) as Transform
           , new CastAlarmM(TMilli) as Cast
	   , CounterMilliC as Counter
           ;

  enum { ALARM_ID = unique("MSP430Timer32khzMapC") };

  Init = MSP430Alarm;

  AlarmMilli = Cast;
  AlarmBaseMilli = Transform;

  Cast.AlarmFrom -> Transform;
  Transform.AlarmFrom -> MSP430Alarm;
  Transform.Counter -> Counter;

  MSP430Alarm.MSP430Timer -> Map.MSP430Timer[ ALARM_ID ];
  MSP430Alarm.MSP430TimerControl -> Map.MSP430TimerControl[ ALARM_ID ];
  MSP430Alarm.MSP430Compare -> Map.MSP430Compare[ ALARM_ID ];
}

