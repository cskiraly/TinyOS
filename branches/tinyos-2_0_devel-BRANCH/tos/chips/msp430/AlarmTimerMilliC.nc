//$Id: AlarmTimerMilliC.nc,v 1.1.2.1 2005-03-10 09:20:21 cssharp Exp $

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

// AlarmTimerMilliC is the alarm to be used to multiplex into TimerMilliC.
configuration AlarmTimerMilliC
{
  provides interface Init;
  provides interface Alarm<TMilli> as AlarmTimerMilli;
  provides interface AlarmBase<TMilli,uint32_t> as AlarmBaseTimerMilli;
}
implementation
{
  components MSP430TimerC
           , new MSP430AlarmM(T32khz) as MSP430Alarm
	   , new TransformAlarmM(TMilli,uint32_t,T32khz,uint16_t,5) as Transform
	   , new CastAlarmM(TMilli) as Cast
	   , CounterMilliC as Counter
	   , MathOpsM
	   , CastOpsM
           ;

  Init = MSP430Alarm;

  AlarmTimerMilli = Cast;
  AlarmBaseTimerMilli = Transform;

  Cast.AlarmFrom -> Transform;
  Transform.AlarmFrom -> MSP430Alarm;
  Transform.Counter -> Counter;
  Transform.MathFrom -> MathOpsM;
  Transform.MathTo -> MathOpsM;
  Transform.CastFromTo -> CastOpsM;

  MSP430Alarm.MSP430Timer -> MSP430TimerC.TimerB;
  MSP430Alarm.MSP430TimerControl -> MSP430TimerC.ControlB4;
  MSP430Alarm.MSP430Compare -> MSP430TimerC.CompareB4;
}

