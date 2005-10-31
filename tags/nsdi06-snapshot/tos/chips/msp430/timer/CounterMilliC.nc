//$Id: CounterMilliC.nc,v 1.1.2.4 2005-05-18 11:25:38 cssharp Exp $

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

// CounterMilliC is the counter to be used for all Millis.
configuration CounterMilliC
{
  provides interface Counter<TMilli,uint32_t> as CounterMilli32;
  provides interface LocalTime<TMilli> as LocalTimeMilli;
}
implementation
{
  components MSP430TimerC
	   , MSP430Counter32khzC
	   , new TransformCounterC(TMilli,uint32_t,T32khz,uint16_t,5,uint32_t) as Transform
	   , new CounterToLocalTimeC(TMilli)
	   ;
  
  CounterMilli32 = Transform.Counter;
  LocalTimeMilli = CounterToLocalTimeC;

  CounterToLocalTimeC.Counter -> Transform;
  Transform.CounterFrom -> MSP430Counter32khzC;
}

