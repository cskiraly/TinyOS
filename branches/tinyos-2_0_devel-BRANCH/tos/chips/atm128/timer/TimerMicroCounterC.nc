//$Id: TimerMicroCounterC.nc,v 1.1.2.2 2005-10-10 03:20:52 mturon Exp $

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

// TimerMicroCounterC is the counter to be used for all TimerMicro[].
configuration TimerMicroCounterC
{
  provides interface Counter<TMicro,uint16_t> as CounterMicro16;
  provides interface Counter<TMicro,uint32_t> as CounterMicro32;
  provides interface LocalTime<TMicro> as LocalTimeMicro;
}
implementation
{
    components HplTimerC,
	new Atm128CounterP(TMicro, uint16_t) as HALCounterMicro, 
	new TransformCounterC(TMicro, uint32_t, TMicro, uint16_t,
			      0, uint32_t) as Transform32,
	new CounterToLocalTimeC(TMicro)
	;
  
  // Top-level interface wiring
  CounterMicro16 = HALCounterMicro.Counter;
  CounterMicro32 = Transform32.Counter;
  LocalTimeMicro = CounterToLocalTimeC;

  // Strap in low-level hardware timer (Timer3)
  HALCounterMicro.Timer -> HplTimerC.Timer3;   // wire async timer to Timer 0

  // Counter Transform Wiring
  Transform32.CounterFrom -> HALCounterMicro;

  CounterToLocalTimeC.Counter -> Transform32;
}

