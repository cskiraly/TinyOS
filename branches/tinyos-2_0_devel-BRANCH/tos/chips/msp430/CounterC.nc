//$Id: CounterC.nc,v 1.1.2.3 2005-02-11 01:56:10 cssharp Exp $

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

configuration CounterC
{
  provides interface Counter<T32khz> as Counter32khz;
  provides interface CounterBase<uint32_t,T32khz> as CounterBase32khz;
  provides interface CounterBase<uint16_t,T32khz> as MSP430Counter32khz;
}
implementation
{
  components MSP430TimerC
           , new MSP430CounterM(T32khz) as MSP430CounterB
	   //, new WidenCounterC(uint32_t,uint16_t,uint16_t,T32khz) as WidenCounterB
	   , new WidenCounterM(uint32_t,uint16_t,uint16_t,T32khz) as WidenCounterB
	   , new CastCounterM(T32khz) as CastCounterB
	   , MathOpsM
	   ;
  
  Counter32khz = CastCounterB.Counter;
  CounterBase32khz = WidenCounterB.Counter;
  MSP430Counter32khz = MSP430CounterB.Counter;

  CastCounterB.CounterFrom -> WidenCounterB.Counter;
  WidenCounterB.CounterFrom -> MSP430CounterB.Counter;
  WidenCounterB.MathTo -> MathOpsM;
  WidenCounterB.MathFrom -> MathOpsM;
  WidenCounterB.MathUpper -> MathOpsM;
  MSP430CounterB.MSP430Timer -> MSP430TimerC.TimerB;
}

