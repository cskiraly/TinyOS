//$Id: CounterC.nc,v 1.1.2.4 2005-02-26 02:32:12 cssharp Exp $

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
  provides interface Counter<TMilli> as CounterMilli;
  provides interface Counter<T32khz> as Counter32khz;
  provides interface CounterBase<uint32_t,TMilli> as CounterBaseMilli;
  provides interface CounterBase<uint32_t,T32khz> as CounterBase32khz;
  provides interface CounterBase<uint16_t,T32khz> as MSP430Counter32khz;
}
implementation
{
  components MSP430TimerC
           , new MSP430CounterM(T32khz) as MSP430CounterB
	   , new TransformCounterM(T32khz,uint32_t,T32khz,uint16_t,0,uint16_t) as XformCounter32khz
	   , new TransformCounterM(TMilli,uint32_t,T32khz,uint16_t,5,uint32_t) as XformCounterMilli
	   , new CastCounterM(T32khz) as CastCounter32khz
	   , new CastCounterM(TMilli) as CastCounterMilli
	   , MathOpsM
	   , CastOpsM
	   ;
  
  CounterMilli = CastCounterMilli.Counter;
  Counter32khz = CastCounter32khz.Counter;
  CounterBaseMilli = XformCounterMilli.Counter;
  CounterBase32khz = XformCounter32khz.Counter;
  MSP430Counter32khz = MSP430CounterB.Counter;

  CastCounter32khz.CounterFrom -> XformCounter32khz.Counter;
  XformCounter32khz.CounterFrom -> MSP430CounterB.Counter;
  XformCounter32khz.MathTo -> MathOpsM;
  XformCounter32khz.MathFrom -> MathOpsM;
  XformCounter32khz.MathUpper -> MathOpsM;
  XformCounter32khz.CastFromTo -> CastOpsM;
  XformCounter32khz.CastUpperTo -> CastOpsM;

  CastCounterMilli.CounterFrom -> XformCounterMilli.Counter;
  XformCounterMilli.CounterFrom -> MSP430CounterB.Counter;
  XformCounterMilli.MathTo -> MathOpsM;
  XformCounterMilli.MathFrom -> MathOpsM;
  XformCounterMilli.MathUpper -> MathOpsM;
  XformCounterMilli.CastFromTo -> CastOpsM;
  XformCounterMilli.CastUpperTo -> CastOpsM;

  MSP430CounterB.MSP430Timer -> MSP430TimerC.TimerB;
}

