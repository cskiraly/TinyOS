//$Id: Timer32khzCounterC.nc,v 1.1.2.1 2005-07-31 03:17:54 mturon Exp $

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

// Timer32khzCounterC is the counter to be used for all Timer32khz[].
configuration Timer32khzCounterC
{
  provides interface Counter<T32khz,uint16_t> as Counter32khz16;
  provides interface Counter<T32khz,uint32_t> as Counter32khz32;
  provides interface LocalTime<T32khz> as LocalTime32khz;
}
implementation
{
    components HPLTimerM,
	new HALCounterM(T32khz, uint8_t) as HALCounter32khz, 
	new TransformCounterC(T32khz, uint16_t, T32khz, uint8_t,
			      0, uint16_t) as Transform16,
	new TransformCounterC(T32khz, uint32_t, T32khz, uint16_t,
			      0, uint32_t) as Transform32,
	new CounterToLocalTimeC(T32khz)
	;
  
  // Top-level interface wiring
  Counter32khz16 = Transform16.Counter;
  Counter32khz32 = Transform32.Counter;
  LocalTime32khz = CounterToLocalTimeC;

  // Strap in low-level hardware timer (Timer0)
  HALCounter32khz.Timer -> HPLTimerM.Timer0;   // wire async timer to Timer 0

  // Counter Transform Wiring
  Transform16.CounterFrom -> HALCounter32khz;
  Transform32.CounterFrom -> Transform16;

  CounterToLocalTimeC.Counter -> Transform32;
}

