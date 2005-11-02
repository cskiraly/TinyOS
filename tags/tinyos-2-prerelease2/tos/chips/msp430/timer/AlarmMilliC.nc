//$Id: AlarmMilliC.nc,v 1.1.2.3 2005-05-18 07:20:21 cssharp Exp $

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
  provides interface Alarm<TMilli,uint32_t> as AlarmMilli32;
}
implementation
{
  components new MSP430Timer32khzC() as MSP430Timer
           , new MSP430AlarmC(T32khz) as MSP430Alarm
           , new TransformAlarmC(TMilli,uint32_t,T32khz,uint16_t,5) as Transform
	   , CounterMilliC as Counter
           ;

  Init = MSP430Alarm;

  AlarmMilli32 = Transform;

  Transform.AlarmFrom -> MSP430Alarm;
  Transform.Counter -> Counter;

  MSP430Alarm.MSP430Timer -> MSP430Timer;
  MSP430Alarm.MSP430TimerControl -> MSP430Timer;
  MSP430Alarm.MSP430Compare -> MSP430Timer;
}

