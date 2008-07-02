//$Id: TimerMilliCounterC.nc,v 1.1.2.1 2005-08-13 01:16:31 idgay Exp $

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

// TimerMilliCounterC is the counter to be used for all TimerMilli[].
configuration TimerMilliCounterC
{
  provides interface Counter<TMilli,uint32_t> as CounterMilli32;
  provides interface LocalTime<TMilli> as LocalTimeMilli;
}
implementation
{
    components HplTimerC,
	//new HALCounterM(T32khz, uint8_t) as HALCounter32khz, 
	Timer32khzCounterC as HALCounter32khz, 
	new TransformCounterC(TMilli, uint32_t, T32khz, uint32_t,
			      5, uint32_t) as Transform,
	new CounterToLocalTimeC(TMilli)
	;
  
  CounterMilli32 = Transform.Counter;
  LocalTimeMilli = CounterToLocalTimeC;

  Transform.CounterFrom -> HALCounter32khz;

  CounterToLocalTimeC.Counter -> Transform;

  //HALCounter32khz.Timer -> HplTimerC.Timer0;   // wire async timer to Timer 0
}
