//$Id: MSP430TimerC.nc,v 1.1.2.1 2005-02-08 23:00:03 cssharp Exp $

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

configuration MSP430TimerC
{
  provides interface MSP430Timer as TimerA;
  provides interface MSP430TimerControl as ControlA0;
  provides interface MSP430TimerControl as ControlA1;
  provides interface MSP430TimerControl as ControlA2;
  provides interface MSP430Compare as CompareA0;
  provides interface MSP430Compare as CompareA1;
  provides interface MSP430Compare as CompareA2;
  provides interface MSP430Capture as CaptureA0;
  provides interface MSP430Capture as CaptureA1;
  provides interface MSP430Capture as CaptureA2;

  provides interface MSP430Timer as TimerB;
  provides interface MSP430TimerControl as ControlB0;
  provides interface MSP430TimerControl as ControlB1;
  provides interface MSP430TimerControl as ControlB2;
  provides interface MSP430TimerControl as ControlB3;
  provides interface MSP430TimerControl as ControlB4;
  provides interface MSP430TimerControl as ControlB5;
  provides interface MSP430TimerControl as ControlB6;
  provides interface MSP430Compare as CompareB0;
  provides interface MSP430Compare as CompareB1;
  provides interface MSP430Compare as CompareB2;
  provides interface MSP430Compare as CompareB3;
  provides interface MSP430Compare as CompareB4;
  provides interface MSP430Compare as CompareB5;
  provides interface MSP430Compare as CompareB6;
  provides interface MSP430Capture as CaptureB0;
  provides interface MSP430Capture as CaptureB1;
  provides interface MSP430Capture as CaptureB2;
  provides interface MSP430Capture as CaptureB3;
  provides interface MSP430Capture as CaptureB4;
  provides interface MSP430Capture as CaptureB5;
  provides interface MSP430Capture as CaptureB6;
}
implementation
{
  components new MSP430TimerM( TAIV_, TAR_, TACTL_, TAIFG, TACLR, TAIE,
               TASSEL0, TASSEL1 ) as MSP430TimerA
           , new MSP430TimerM( TBIV_, TBR_, TBCTL_, TBIFG, TBCLR, TBIE, 
	       TBSSEL0, TBSSEL1 ) as MSP430TimerB
	   , new MSP430TimerCCC( TACCTL0_, TACCR0_ ) as MSP430TimerA0
	   , new MSP430TimerCCC( TACCTL1_, TACCR1_ ) as MSP430TimerA1
	   , new MSP430TimerCCC( TACCTL2_, TACCR2_ ) as MSP430TimerA2
	   , new MSP430TimerCCC( TBCCTL0_, TBCCR0_ ) as MSP430TimerB0
	   , new MSP430TimerCCC( TBCCTL1_, TBCCR1_ ) as MSP430TimerB1
	   , new MSP430TimerCCC( TBCCTL2_, TBCCR2_ ) as MSP430TimerB2
	   , new MSP430TimerCCC( TBCCTL3_, TBCCR3_ ) as MSP430TimerB3
	   , new MSP430TimerCCC( TBCCTL4_, TBCCR4_ ) as MSP430TimerB4
	   , new MSP430TimerCCC( TBCCTL5_, TBCCR5_ ) as MSP430TimerB5
	   , new MSP430TimerCCC( TBCCTL6_, TBCCR6_ ) as MSP430TimerB6
	   , MSP430TimerCommonM as Common
	   ;

  // Timer A
  TimerA = MSP430TimerA.Timer;
  MSP430TimerA.Overflow -> MSP430TimerA.Event[10];
  MSP430TimerA.VectorTimerX0 -> Common.VectorTimerA0;
  MSP430TimerA.VectorTimerX1 -> Common.VectorTimerA1;

  // Timer A0
  ControlA0 = MSP430TimerA0.Control;
  CompareA0 = MSP430TimerA0.Compare;
  CaptureA0 = MSP430TimerA0.Capture;
  MSP430TimerA0.Timer -> MSP430TimerA.Timer;

  // Timer A1
  ControlA1 = MSP430TimerA1.Control;
  CompareA1 = MSP430TimerA1.Compare;
  CaptureA1 = MSP430TimerA1.Capture;
  MSP430TimerA1.Timer -> MSP430TimerA.Timer;

  // Timer A2
  ControlA2 = MSP430TimerA2.Control;
  CompareA2 = MSP430TimerA2.Compare;
  CaptureA2 = MSP430TimerA2.Capture;
  MSP430TimerA2.Timer -> MSP430TimerA.Timer;

  // Timer B
  TimerB = MSP430TimerB.Timer;
  MSP430TimerB.Overflow -> MSP430TimerB.Event[14];
  MSP430TimerA.VectorTimerX0 -> Common.VectorTimerB0;
  MSP430TimerA.VectorTimerX1 -> Common.VectorTimerB1;

  // Timer B0
  ControlB0 = MSP430TimerB0.Control;
  CompareB0 = MSP430TimerB0.Compare;
  CaptureB0 = MSP430TimerB0.Capture;
  MSP430TimerB0.Timer -> MSP430TimerB.Timer;

  // Timer B1
  ControlB1 = MSP430TimerB1.Control;
  CompareB1 = MSP430TimerB1.Compare;
  CaptureB1 = MSP430TimerB1.Capture;
  MSP430TimerB1.Timer -> MSP430TimerB.Timer;

  // Timer B2
  ControlB2 = MSP430TimerB2.Control;
  CompareB2 = MSP430TimerB2.Compare;
  CaptureB2 = MSP430TimerB2.Capture;
  MSP430TimerB2.Timer -> MSP430TimerB.Timer;

  // Timer B3
  ControlB3 = MSP430TimerB3.Control;
  CompareB3 = MSP430TimerB3.Compare;
  CaptureB3 = MSP430TimerB3.Capture;
  MSP430TimerB3.Timer -> MSP430TimerB.Timer;

  // Timer B4
  ControlB4 = MSP430TimerB4.Control;
  CompareB4 = MSP430TimerB4.Compare;
  CaptureB4 = MSP430TimerB4.Capture;
  MSP430TimerB4.Timer -> MSP430TimerB.Timer;

  // Timer B5
  ControlB5 = MSP430TimerB5.Control;
  CompareB5 = MSP430TimerB5.Compare;
  CaptureB5 = MSP430TimerB5.Capture;
  MSP430TimerB5.Timer -> MSP430TimerB.Timer;

  // Timer B6
  ControlB6 = MSP430TimerB6.Control;
  CompareB6 = MSP430TimerB6.Compare;
  CaptureB6 = MSP430TimerB6.Capture;
  MSP430TimerB6.Timer -> MSP430TimerB.Timer;
}

