//$Id: AlarmC.nc,v 1.1.2.3 2005-02-11 01:56:10 cssharp Exp $

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

configuration AlarmC
{
  provides interface Init;

  // alarms required by standard tinyos components
  provides interface Alarm<T32khz> as AlarmTimer32khz;
  //provides interface Alarm<T32khz> as AlarmTimerAsync32khz;

  // extra alarms to be used by applications
  //provides interface Alarm<T32khz> as Alarm32khz1;
  //provides interface Alarm<T32khz> as Alarm32khz2;
  // ...

  //provides interface Alarm<TMicro> as AlarmMicro1;
  //provides interface Alarm<TMicro> as AlarmMicro2;
  // ...
}
implementation
{
  components MSP430TimerC
           , new MSP430AlarmM(T32khz) as MSP430Alarm32khz
	   //, new WidenAlarmC(uint32_t,uint16_t,T32khz) as Widen32khz
	   , new WidenAlarmM(uint32_t,uint16_t,T32khz) as WidenAlarm32khz
	   , new CastAlarmM(T32khz) as CastAlarm32khz
	   , CounterC
	   , MathOpsM
           ;

  Init = MSP430Alarm32khz;

  AlarmTimer32khz = CastAlarm32khz;

  CastAlarm32khz.AlarmFrom -> WidenAlarm32khz.Alarm;
  WidenAlarm32khz.AlarmFrom -> MSP430Alarm32khz.Alarm;
  WidenAlarm32khz.Counter -> CounterC.CounterBase32khz;
  WidenAlarm32khz.MathFrom -> MathOpsM;
  WidenAlarm32khz.MathTo -> MathOpsM;
  MSP430Alarm32khz.MSP430Timer -> MSP430TimerC.TimerB;
  MSP430Alarm32khz.MSP430TimerControl -> MSP430TimerC.ControlB3;
  MSP430Alarm32khz.MSP430Compare -> MSP430TimerC.CompareB3;
}

