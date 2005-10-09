//$Id: MSP430Timer32khzMapC.nc,v 1.1.2.1 2005-10-09 02:57:37 vlahan Exp $

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

/*
  MSP430Timer32khzMapC presents as paramaterized interfaces all of the 32khz
  hardware timers on the MSP430 that are available for compile time allocation
  by "new Alarm32khzC()", "new AlarmMilliC()", and so on.

  Platforms based on the MSP430 are encouraged to copy in and override this
  file, presenting only the hardware timers that are available for allocation
  on that platform.
*/

configuration MSP430Timer32khzMapC
{
  provides interface MSP430Timer[ uint8_t id ];
  provides interface MSP430TimerControl[ uint8_t id ];
  provides interface MSP430Compare[ uint8_t id ];
}
implementation
{
  components MSP430TimerC;

  MSP430Timer[0] = MSP430TimerC.TimerB;
  MSP430TimerControl[0] = MSP430TimerC.ControlB0;
  MSP430Compare[0] = MSP430TimerC.CompareB0;

  MSP430Timer[1] = MSP430TimerC.TimerB;
  MSP430TimerControl[1] = MSP430TimerC.ControlB1;
  MSP430Compare[1] = MSP430TimerC.CompareB1;

  MSP430Timer[2] = MSP430TimerC.TimerB;
  MSP430TimerControl[2] = MSP430TimerC.ControlB2;
  MSP430Compare[2] = MSP430TimerC.CompareB2;

  MSP430Timer[3] = MSP430TimerC.TimerB;
  MSP430TimerControl[3] = MSP430TimerC.ControlB3;
  MSP430Compare[3] = MSP430TimerC.CompareB3;

  MSP430Timer[4] = MSP430TimerC.TimerB;
  MSP430TimerControl[4] = MSP430TimerC.ControlB4;
  MSP430Compare[4] = MSP430TimerC.CompareB4;

  MSP430Timer[5] = MSP430TimerC.TimerB;
  MSP430TimerControl[5] = MSP430TimerC.ControlB5;
  MSP430Compare[5] = MSP430TimerC.CompareB5;

  MSP430Timer[6] = MSP430TimerC.TimerB;
  MSP430TimerControl[6] = MSP430TimerC.ControlB6;
  MSP430Compare[6] = MSP430TimerC.CompareB6;
}

